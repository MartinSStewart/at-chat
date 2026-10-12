//! Lets the Lamdera backend hold a WebSocket that needs request headers. Its own
//! WebSocket client only takes a URL, and Slack turns away any connection that
//! doesn't carry the `d` cookie.
//!
//! The backend connects to `/file/websocket-relay` and waits for [`READY`]. It then
//! sends a [`RelayRequest`], the relay checks the secret key and opens the upstream
//! socket with the headers asked for, and from then on every message passes through
//! unchanged in both directions. When either side closes, so does the other.
//!
//! The secret key goes in the first message rather than a header or the url because
//! the backend can't set headers, and a url ends up in access logs.

use crate::AppState;
use axum::extract::State;
use axum::extract::ws::{CloseFrame, Message, WebSocket, WebSocketUpgrade};
use axum::response::Response;
use futures_util::{SinkExt, StreamExt};
use serde::Deserialize;
use std::sync::{Arc, Mutex};
use std::time::Duration;
use subtle::ConstantTimeEq;
use tokio_tungstenite::tungstenite;
use tokio_tungstenite::tungstenite::client::IntoClientRequest;
use tokio_tungstenite::tungstenite::http::{HeaderName, HeaderValue};

/// Sent as soon as the relay accepts a connection. The backend's WebSocket only
/// opens once something listens to it, so this is how it knows when it can send.
pub const READY: &str = "relay_ready";

/// Nothing is relayed until the request arrives, and a connection that never
/// sends one shouldn't sit open forever.
const REQUEST_TIMEOUT: Duration = Duration::from_secs(10);

// Close codes 4000 to 4999 are left for applications to use.
const INVALID_REQUEST: u16 = 4000;
const INVALID_SECRET_KEY: u16 = 4001;
const UPSTREAM_FAILED: u16 = 4002;

/// A close reason can be at most 123 bytes.
const MAX_CLOSE_REASON_BYTES: usize = 123;

#[derive(Deserialize)]
struct RelayRequest {
    #[serde(rename = "secretKey")]
    secret_key: String,
    url: String,
    headers: Vec<(String, String)>,
}

pub async fn relay_endpoint(
    upgrade: WebSocketUpgrade,
    State(state): State<Arc<Mutex<AppState>>>,
) -> Response {
    let secret_key: Vec<u8> = state.lock().unwrap().secret_key.clone();
    upgrade.on_upgrade(move |socket| relay(socket, secret_key))
}

async fn relay(mut socket: WebSocket, secret_key: Vec<u8>) {
    if socket.send(Message::text(READY)).await.is_err() {
        return;
    }

    let request: RelayRequest = match tokio::time::timeout(REQUEST_TIMEOUT, socket.recv()).await {
        Ok(Some(Ok(Message::Text(text)))) => match serde_json::from_str(text.as_str()) {
            Ok(request) => request,
            Err(_) => return close(socket, INVALID_REQUEST, "Invalid relay request").await,
        },
        _ => return close(socket, INVALID_REQUEST, "Expected a relay request").await,
    };

    let authorized: bool = request.secret_key.as_bytes().ct_eq(&secret_key).into();
    if !authorized {
        return close(socket, INVALID_SECRET_KEY, "Invalid secret key").await;
    }

    let mut upstream_request = match request.url.as_str().into_client_request() {
        Ok(upstream_request) => upstream_request,
        Err(_) => return close(socket, INVALID_REQUEST, "Invalid url").await,
    };
    for (name, value) in request.headers {
        match (
            HeaderName::from_bytes(name.as_bytes()),
            HeaderValue::from_str(&value),
        ) {
            (Ok(name2), Ok(value2)) => {
                upstream_request.headers_mut().insert(name2, value2);
            }
            _ => return close(socket, INVALID_REQUEST, "Invalid header").await,
        }
    }

    let upstream = match tokio_tungstenite::connect_async(upstream_request).await {
        Ok((upstream, _)) => upstream,
        // The url is left out of the reason since it can carry a token.
        Err(error) => {
            return close(
                socket,
                UPSTREAM_FAILED,
                &format!("Couldn't connect: {error}"),
            )
            .await;
        }
    };

    pipe(socket, upstream).await;
}

/// Passes messages between the backend and upstream until either one closes.
async fn pipe(
    socket: WebSocket,
    upstream: tokio_tungstenite::WebSocketStream<
        tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>,
    >,
) {
    let (mut upstream_out, mut upstream_in) = upstream.split();
    let (mut downstream_out, mut downstream_in) = socket.split();

    let to_upstream = async move {
        while let Some(Ok(message)) = downstream_in.next().await {
            let forwarded: tungstenite::Message = match message {
                Message::Text(text) => tungstenite::Message::text(text.as_str()),
                Message::Binary(bytes) => tungstenite::Message::binary(bytes),
                Message::Close(frame) => {
                    let _ = upstream_out
                        .send(tungstenite::Message::Close(frame.map(|frame2| {
                            tungstenite::protocol::CloseFrame {
                                code: frame2.code.into(),
                                reason: frame2.reason.as_str().into(),
                            }
                        })))
                        .await;
                    return;
                }
                // Each side answers its own pings.
                Message::Ping(_) | Message::Pong(_) => continue,
            };
            if upstream_out.send(forwarded).await.is_err() {
                return;
            }
        }
        let _ = upstream_out.close().await;
    };

    let to_downstream = async move {
        let close_frame: CloseFrame = loop {
            match upstream_in.next().await {
                Some(Ok(message)) => {
                    let forwarded: Message = match message {
                        tungstenite::Message::Text(text) => Message::text(text.as_str()),
                        tungstenite::Message::Binary(bytes) => Message::binary(bytes),
                        tungstenite::Message::Close(frame) => {
                            break match frame {
                                Some(frame2) => CloseFrame {
                                    code: frame2.code.into(),
                                    reason: frame2.reason.as_str().into(),
                                },
                                None => CloseFrame {
                                    code: 1000,
                                    reason: "".into(),
                                },
                            };
                        }
                        tungstenite::Message::Ping(_)
                        | tungstenite::Message::Pong(_)
                        | tungstenite::Message::Frame(_) => continue,
                    };
                    if downstream_out.send(forwarded).await.is_err() {
                        return;
                    }
                }
                Some(Err(error)) => {
                    break CloseFrame {
                        code: UPSTREAM_FAILED,
                        reason: truncate(&format!("Upstream failed: {error}")).into(),
                    };
                }
                None => {
                    break CloseFrame {
                        code: UPSTREAM_FAILED,
                        reason: "Upstream ended without closing".into(),
                    };
                }
            }
        };
        let _ = downstream_out.send(Message::Close(Some(close_frame))).await;
    };

    tokio::select! {
        () = to_upstream => {}
        () = to_downstream => {}
    }
}

async fn close(mut socket: WebSocket, code: u16, reason: &str) {
    let _ = socket
        .send(Message::Close(Some(CloseFrame {
            code,
            reason: truncate(reason).into(),
        })))
        .await;
}

fn truncate(text: &str) -> String {
    let mut end: usize = text.len().min(MAX_CLOSE_REASON_BYTES);
    while !text.is_char_boundary(end) {
        end -= 1;
    }
    text[..end].to_owned()
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::Router;
    use axum::http::HeaderMap;
    use axum::response::IntoResponse;
    use axum::routing::get;

    type Client = tokio_tungstenite::WebSocketStream<
        tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>,
    >;

    async fn serve(router: Router) -> String {
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0")
            .await
            .expect("failed to bind test server");
        let address = listener.local_addr().unwrap();
        tokio::spawn(async move {
            let _ = axum::serve(listener, router).await;
        });
        format!("ws://{address}")
    }

    // Stands in for Slack: refuses anything without the cookie, says hello, then
    // echoes every text message back with "echo: " in front.
    async fn spawn_upstream() -> String {
        serve(Router::new().route(
            "/",
            get(async |upgrade: WebSocketUpgrade, headers: HeaderMap| {
                let has_cookie = headers
                    .get("cookie")
                    .is_some_and(|cookie| cookie == "d=the-cookie");
                if has_cookie {
                    upgrade.on_upgrade(async |mut socket: WebSocket| {
                        let _ = socket.send(Message::text("hello")).await;
                        while let Some(Ok(Message::Text(text))) = socket.recv().await {
                            if text.as_str() == "close please" {
                                let _ = socket
                                    .send(Message::Close(Some(CloseFrame {
                                        code: 4321,
                                        reason: "asked to".into(),
                                    })))
                                    .await;
                                return;
                            }
                            let _ = socket
                                .send(Message::text(format!("echo: {}", text.as_str())))
                                .await;
                        }
                    })
                } else {
                    axum::http::StatusCode::UNAUTHORIZED.into_response()
                }
            }),
        ))
        .await
    }

    async fn spawn_relay() -> String {
        let state = Arc::new(Mutex::new(AppState {
            secret_key: b"the-secret".to_vec(),
        }));
        let url = serve(
            Router::new()
                .route("/file/websocket-relay", get(relay_endpoint))
                .with_state(state),
        )
        .await;
        format!("{url}/file/websocket-relay")
    }

    async fn connect(relay_url: &str) -> Client {
        let (mut socket, _) = tokio_tungstenite::connect_async(relay_url)
            .await
            .expect("failed to connect to the relay");
        assert_eq!(
            next_text(&mut socket).await,
            READY,
            "the relay should say it's ready before anything else"
        );
        socket
    }

    async fn send_request(socket: &mut Client, secret_key: &str, upstream_url: &str, cookie: &str) {
        let request = serde_json::json!({
            "secretKey": secret_key,
            "url": upstream_url,
            "headers": [["Cookie", cookie]],
        });
        socket
            .send(tungstenite::Message::text(request.to_string()))
            .await
            .expect("failed to send the relay request");
    }

    async fn next_text(socket: &mut Client) -> String {
        match socket.next().await {
            Some(Ok(tungstenite::Message::Text(text))) => text.as_str().to_owned(),
            other => panic!("expected a text message, got {other:?}"),
        }
    }

    async fn next_close_code(socket: &mut Client) -> u16 {
        match socket.next().await {
            Some(Ok(tungstenite::Message::Close(Some(frame)))) => frame.code.into(),
            other => panic!("expected a close frame, got {other:?}"),
        }
    }

    #[tokio::test]
    async fn relays_both_ways_with_the_requested_headers() {
        let upstream_url = spawn_upstream().await;
        let relay_url = spawn_relay().await;
        let mut socket = connect(&relay_url).await;

        send_request(&mut socket, "the-secret", &upstream_url, "d=the-cookie").await;
        assert_eq!(
            next_text(&mut socket).await,
            "hello",
            "what upstream sends should come through"
        );

        socket
            .send(tungstenite::Message::text("ping"))
            .await
            .expect("failed to send");
        assert_eq!(
            next_text(&mut socket).await,
            "echo: ping",
            "what the backend sends should reach upstream"
        );
    }

    #[tokio::test]
    async fn passes_on_upstream_closing() {
        let upstream_url = spawn_upstream().await;
        let relay_url = spawn_relay().await;
        let mut socket = connect(&relay_url).await;

        send_request(&mut socket, "the-secret", &upstream_url, "d=the-cookie").await;
        assert_eq!(
            next_text(&mut socket).await,
            "hello",
            "upstream should say hello"
        );
        socket
            .send(tungstenite::Message::text("close please"))
            .await
            .expect("failed to send");
        assert_eq!(
            next_close_code(&mut socket).await,
            4321,
            "upstream's close code should reach the backend"
        );
    }

    #[tokio::test]
    async fn refuses_the_wrong_secret_key() {
        let upstream_url = spawn_upstream().await;
        let relay_url = spawn_relay().await;
        let mut socket = connect(&relay_url).await;

        send_request(&mut socket, "not-the-secret", &upstream_url, "d=the-cookie").await;
        assert_eq!(
            next_close_code(&mut socket).await,
            INVALID_SECRET_KEY,
            "a request with the wrong secret key must not be relayed"
        );
    }

    #[tokio::test]
    async fn closes_when_upstream_refuses_the_connection() {
        let upstream_url = spawn_upstream().await;
        let relay_url = spawn_relay().await;
        let mut socket = connect(&relay_url).await;

        send_request(&mut socket, "the-secret", &upstream_url, "d=wrong-cookie").await;
        assert_eq!(
            next_close_code(&mut socket).await,
            UPSTREAM_FAILED,
            "the backend should hear that upstream couldn't be reached"
        );
    }

    #[test]
    fn truncates_close_reasons_on_a_char_boundary() {
        let reason = truncate(&"é".repeat(100));
        assert!(
            reason.len() <= MAX_CLOSE_REASON_BYTES && reason.chars().all(|char| char == 'é'),
            "the reason should fit in a close frame without splitting a character"
        );
    }
}
