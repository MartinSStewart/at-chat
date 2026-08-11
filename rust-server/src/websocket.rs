//! The WebSocket endpoints voice chat is being moved onto, in place of the
//! WebRTC peer connections in `elm-pkg-js/voice-chat.js`.
//!
//! There are two. `/file/websocket` mirrors each message back to the sender,
//! which is what the admin page's streaming test measures itself against.
//! `/file/websocket/{room_id}` is the real shape: it passes each message on to
//! everyone else in the same room and never back to whoever sent it.

use axum::Extension;
use axum::body::Body;
use axum::extract::Path;
use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use axum::response::Response;
use futures_util::{SinkExt, StreamExt};
use std::collections::HashMap;
use std::sync::Arc;
use std::sync::Mutex;
use std::sync::atomic::{AtomicU64, Ordering};
use tokio::sync::broadcast;

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

/// Everyone currently connected, grouped by the room id from the URL. A room
/// exists only while somebody is in it.
pub type Rooms = Arc<Mutex<HashMap<String, broadcast::Sender<Broadcast>>>>;

/// How far behind a client may fall before it starts losing messages. Media
/// arrives faster than a stalled client can drain it, so the alternative to
/// dropping the backlog is growing it without limit; a client that falls this
/// far behind misses what it slept through and carries on from the present.
const ROOM_BACKLOG: usize = 256;

/// A message on its way to the rest of the room, tagged with the connection it
/// came from so that connection can skip it.
#[derive(Clone)]
pub struct Broadcast {
    from: u64,
    message: Message,
}

static NEXT_CONNECTION_ID: AtomicU64 = AtomicU64::new(0);

pub fn rooms() -> Rooms {
    Arc::new(Mutex::new(HashMap::new()))
}

pub async fn room_endpoint(
    upgrade: WebSocketUpgrade,
    Path(room_id): Path<String>,
    Extension(rooms): Extension<Rooms>,
) -> Response<Body> {
    upgrade.on_upgrade(move |socket| join_room(socket, room_id, rooms))
}

async fn join_room(socket: WebSocket, room_id: String, rooms: Rooms) {
    let connection_id = NEXT_CONNECTION_ID.fetch_add(1, Ordering::Relaxed);

    // Subscribing while the map is still locked is what stops an empty room
    // from being cleaned up in the gap between being handed out and being
    // joined, which would put this connection in a room nobody else can reach.
    let (sender, mut receiver) = {
        let mut rooms2 = rooms.lock().unwrap();
        let sender = rooms2
            .entry(room_id.clone())
            .or_insert_with(|| broadcast::channel(ROOM_BACKLOG).0)
            .clone();
        let receiver = sender.subscribe();
        (sender, receiver)
    };

    let (mut outgoing, mut incoming) = socket.split();

    let forward = tokio::spawn(async move {
        loop {
            match receiver.recv().await {
                // The one connection that does not get a copy is the sender.
                Ok(broadcast) if broadcast.from == connection_id => {}
                Ok(broadcast) => {
                    if outgoing.send(broadcast.message).await.is_err() {
                        break;
                    }
                }
                // Too far behind. Skipping ahead is the intended behaviour.
                Err(broadcast::error::RecvError::Lagged(_)) => {}
                Err(broadcast::error::RecvError::Closed) => break,
            }
        }
    });

    while let Some(Ok(message)) = incoming.next().await {
        match message {
            Message::Text(_) | Message::Binary(_) => {
                // Errors here only mean the room is empty apart from the sender.
                let _ = sender.send(Broadcast {
                    from: connection_id,
                    message,
                });
            }
            Message::Close(_) => break,
            Message::Ping(_) | Message::Pong(_) => {}
        }
    }

    // Waiting for the aborted task guarantees its receiver is dropped before
    // the count below is read, so the last one out really does see zero.
    forward.abort();
    let _ = forward.await;

    let mut rooms2 = rooms.lock().unwrap();
    if rooms2
        .get(&room_id)
        .is_some_and(|room| room.receiver_count() == 0)
    {
        rooms2.remove(&room_id);
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

    // --- the room endpoint ---

    // Serve the room endpoint on a random local port. Returns the URL to
    // connect to, minus the room id, and the map of live rooms.
    async fn spawn_room_server() -> (String, Rooms) {
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0")
            .await
            .expect("failed to bind test server");
        let url = format!("ws://{}/file/websocket", listener.local_addr().unwrap());

        let rooms = rooms();
        let router = Router::new()
            .route("/file/websocket/{room_id}", get(room_endpoint))
            .layer(Extension(rooms.clone()));

        tokio::spawn(async move {
            let _ = axum::serve(listener, router).await;
        });

        (url, rooms)
    }

    type Client = tokio_tungstenite::WebSocketStream<
        tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>,
    >;

    async fn join(url: &str, room_id: &str) -> Client {
        let (socket, _) = tokio_tungstenite::connect_async(format!("{url}/{room_id}"))
            .await
            .expect("failed to connect to the room endpoint");
        socket
    }

    // A client is connected before the server has finished joining it to its
    // room, so waiting on the room's own count is what makes these tests
    // deterministic rather than dependent on a sleep being long enough.
    async fn wait_for_members(rooms: &Rooms, room_id: &str, expected: usize) {
        for _ in 0..200 {
            let count = rooms
                .lock()
                .unwrap()
                .get(room_id)
                .map_or(0, broadcast::Sender::receiver_count);
            if count == expected {
                return;
            }
            tokio::time::sleep(std::time::Duration::from_millis(10)).await;
        }
        panic!("room {room_id} never reached {expected} members");
    }

    // Nothing should arrive. Waiting for a message that must not come needs a
    // deadline, and 300ms is far longer than a loopback round trip.
    async fn assert_silent(socket: &mut Client, context: &str) {
        let result =
            tokio::time::timeout(std::time::Duration::from_millis(300), socket.next()).await;
        assert!(result.is_err(), "{context}");
    }

    #[tokio::test]
    async fn passes_messages_to_the_room_but_never_back_to_the_sender() {
        let (url, rooms) = spawn_room_server().await;
        let mut alice = join(&url, "room-a").await;
        let mut bob = join(&url, "room-a").await;
        wait_for_members(&rooms, "room-a", 2).await;

        alice
            .send(tungstenite::Message::text("hello"))
            .await
            .expect("failed to send");

        let received = bob
            .next()
            .await
            .expect("bob's connection closed")
            .expect("failed to receive");
        assert_eq!(
            received,
            tungstenite::Message::text("hello"),
            "the other connection in the room should receive the message unchanged"
        );

        assert_silent(
            &mut alice,
            "the sender must not receive its own message back",
        )
        .await;
    }

    #[tokio::test]
    async fn reaches_every_other_member_of_the_room() {
        let (url, rooms) = spawn_room_server().await;
        let mut alice = join(&url, "room-a").await;
        let mut bob = join(&url, "room-a").await;
        let mut carol = join(&url, "room-a").await;
        wait_for_members(&rooms, "room-a", 3).await;

        let payload: Vec<u8> = vec![1, 2, 3, 4];
        alice
            .send(tungstenite::Message::binary(payload.clone()))
            .await
            .expect("failed to send");

        for (name, listener) in [("bob", &mut bob), ("carol", &mut carol)] {
            let received = match listener.next().await {
                Some(result) => result.expect("failed to receive"),
                None => panic!("{name}'s connection closed"),
            };
            assert_eq!(
                received,
                tungstenite::Message::binary(payload.clone()),
                "every other member of the room should receive the message"
            );
        }

        assert_silent(
            &mut alice,
            "the sender must not receive its own message back",
        )
        .await;
    }

    #[tokio::test]
    async fn keeps_separate_rooms_apart() {
        let (url, rooms) = spawn_room_server().await;
        let mut alice = join(&url, "room-a").await;
        let mut bob = join(&url, "room-b").await;
        wait_for_members(&rooms, "room-a", 1).await;
        wait_for_members(&rooms, "room-b", 1).await;

        alice
            .send(tungstenite::Message::text("only for room-a"))
            .await
            .expect("failed to send");

        assert_silent(&mut bob, "a message must not cross into a different room").await;
    }

    #[tokio::test]
    async fn forgets_a_room_once_everyone_has_left() {
        let (url, rooms) = spawn_room_server().await;
        let mut alice = join(&url, "room-a").await;
        let mut bob = join(&url, "room-a").await;
        wait_for_members(&rooms, "room-a", 2).await;

        alice.close(None).await.expect("failed to close");
        wait_for_members(&rooms, "room-a", 1).await;
        assert!(
            rooms.lock().unwrap().contains_key("room-a"),
            "the room should survive while somebody is still in it"
        );

        bob.close(None).await.expect("failed to close");
        for _ in 0..200 {
            if rooms.lock().unwrap().is_empty() {
                return;
            }
            tokio::time::sleep(std::time::Duration::from_millis(10)).await;
        }
        panic!("the room should be dropped once the last connection leaves");
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
