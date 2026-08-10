//! A WebSocket endpoint that echoes back whatever the client sends it.
//!
//! This is the transport voice chat is being moved onto, in place of the WebRTC
//! peer connections in `elm-pkg-js/voice-chat.js`. Nothing is routed between
//! participants yet: the server mirrors each message straight back to the
//! sender, which is enough to build and test the client side against.

use axum::body::Body;
use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use axum::response::Response;

/// Completes the HTTP upgrade handshake and hands the socket to [`echo`].
pub async fn websocket_endpoint(upgrade: WebSocketUpgrade) -> Response<Body> {
    upgrade.on_upgrade(echo)
}

async fn echo(mut socket: WebSocket) {
    // `recv` yields `None` when the client goes away and `Some(Err(_))` when the
    // connection breaks. Either way there is nothing left to echo to, so the
    // pattern below ends the loop and drops the socket.
    while let Some(Ok(message)) = socket.recv().await {
        match message {
            Message::Text(_) | Message::Binary(_) => {
                if socket.send(message).await.is_err() {
                    break;
                }
            }
            Message::Close(_) => break,
            // Answered for us by the underlying WebSocket implementation.
            Message::Ping(_) | Message::Pong(_) => {}
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::Router;
    use axum::routing::get;
    use futures_util::{SinkExt, StreamExt};
    use tokio_tungstenite::tungstenite;

    // Serve the endpoint on a random local port and return the URL to connect to.
    async fn spawn_echo_server() -> String {
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0")
            .await
            .expect("failed to bind test server");
        let url = format!("ws://{}/file/websocket", listener.local_addr().unwrap());

        let router = Router::new().route("/file/websocket", get(websocket_endpoint));

        tokio::spawn(async move {
            let _ = axum::serve(listener, router).await;
        });

        url
    }

    #[tokio::test]
    async fn echoes_text_messages_back_in_order() {
        let (mut socket, _) = tokio_tungstenite::connect_async(spawn_echo_server().await)
            .await
            .expect("failed to connect to the echo endpoint");

        for text in ["hello", "", "second message"] {
            socket
                .send(tungstenite::Message::text(text))
                .await
                .expect("failed to send");

            let reply = socket
                .next()
                .await
                .expect("connection closed instead of replying")
                .expect("failed to receive");

            assert_eq!(
                reply,
                tungstenite::Message::text(text),
                "the endpoint should echo each text message back unchanged"
            );
        }
    }

    #[tokio::test]
    async fn echoes_binary_messages_back() {
        let (mut socket, _) = tokio_tungstenite::connect_async(spawn_echo_server().await)
            .await
            .expect("failed to connect to the echo endpoint");

        let payload: Vec<u8> = vec![0, 1, 2, 253, 254, 255];
        socket
            .send(tungstenite::Message::binary(payload.clone()))
            .await
            .expect("failed to send");

        let reply = socket
            .next()
            .await
            .expect("connection closed instead of replying")
            .expect("failed to receive");

        assert_eq!(
            reply,
            tungstenite::Message::binary(payload),
            "the endpoint should echo binary messages back unchanged"
        );
    }

    #[tokio::test]
    async fn closing_the_socket_ends_the_connection() {
        let (mut socket, _) = tokio_tungstenite::connect_async(spawn_echo_server().await)
            .await
            .expect("failed to connect to the echo endpoint");

        socket.close(None).await.expect("failed to close");

        // Once the close is acknowledged the stream ends rather than hanging.
        while let Some(Ok(message)) = socket.next().await {
            assert!(
                message.is_close(),
                "no messages other than the close acknowledgement should arrive"
            );
        }
    }
}
