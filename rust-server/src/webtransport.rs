//! WebTransport echo server, intended to eventually carry voice chat audio and other
//! realtime data.
//!
//! WebTransport runs over HTTP/3, which means QUIC over UDP with TLS, so it can't share
//! the TCP listener the rest of the API uses. It gets its own UDP port instead.
//!
//! A browser refuses to connect to a server with a self-signed certificate unless it is
//! told up front which certificate to expect, via the `serverCertificateHashes` option.
//! The certificate is generated when the server starts and its SHA-256 hash is handed to
//! the frontend over the regular HTTP API (`/file/webtransport-info` in main.rs).
//! Browsers only accept `serverCertificateHashes` for certificates valid for at most 14
//! days, and `Identity::self_signed` generates exactly that, so the server has to be
//! restarted at least every two weeks for connections to keep working.

use std::net::Ipv4Addr;
use std::net::SocketAddr;
use std::time::Duration;
use wtransport::Endpoint;
use wtransport::Identity;
use wtransport::RecvStream;
use wtransport::SendStream;
use wtransport::ServerConfig;
use wtransport::endpoint::IncomingSession;
use wtransport::tls::Sha256Digest;

/// UDP port the WebTransport server listens on. The rest of the API is on TCP port 3000.
pub const PORT: u16 = 3001;

/// The certificate the browser is asked to pin, as 32 bytes. Sent to the frontend so it
/// can pass it to `new WebTransport(url, { serverCertificateHashes: ... })`.
pub fn certificate_hash(identity: &Identity) -> Sha256Digest {
    identity.certificate_chain().as_slice()[0].hash()
}

pub fn self_signed_identity() -> Option<Identity> {
    Identity::self_signed(["localhost", "127.0.0.1", "::1", "at-chat.app"]).ok()
}

pub async fn serve(identity: Identity) {
    let config = ServerConfig::builder()
        .with_bind_address(SocketAddr::new(Ipv4Addr::UNSPECIFIED.into(), PORT))
        .with_identity(identity)
        .keep_alive_interval(Some(Duration::from_secs(3)))
        .build();

    match Endpoint::server(config) {
        Ok(endpoint) => {
            #[expect(
                clippy::infinite_loop,
                reason = "The endpoint accepts sessions until the process exits"
            )]
            loop {
                tokio::spawn(handle_session(endpoint.accept().await));
            }
        }
        Err(error) => {
            println!("WebTransport server didn't start: {error}");
        }
    }
}

async fn handle_session(incoming_session: IncomingSession) {
    if let Err(error) = handle_session_impl(incoming_session).await {
        println!("WebTransport session ended: {error}");
    }
}

async fn handle_session_impl(
    incoming_session: IncomingSession,
) -> Result<(), Box<dyn std::error::Error>> {
    let session_request = incoming_session.await?;
    let connection = session_request.accept().await?;

    loop {
        tokio::select! {
            stream = connection.accept_bi() => {
                let (send_stream, receive_stream) = stream?;
                tokio::spawn(echo_stream(send_stream, receive_stream));
            }
            datagram = connection.receive_datagram() => {
                connection.send_datagram(datagram?.payload())?;
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use wtransport::ClientConfig;

    #[tokio::test]
    async fn echoes_back_what_the_client_sends() {
        let identity = self_signed_identity().unwrap();
        let hash = certificate_hash(&identity);

        tokio::spawn(serve(identity));

        // Lets the spawned task bind the UDP socket before we try to connect to it.
        tokio::task::yield_now().await;

        let endpoint = Endpoint::client(
            ClientConfig::builder()
                .with_bind_address(SocketAddr::new(Ipv4Addr::LOCALHOST.into(), 0))
                .with_server_certificate_hashes([hash])
                .build(),
        )
        .unwrap();

        let connection = endpoint
            .connect(format!("https://localhost:{PORT}"))
            .await
            .unwrap();

        let (mut send_stream, mut receive_stream) =
            connection.open_bi().await.unwrap().await.unwrap();

        send_stream.write_all(b"Hello world!").await.unwrap();
        send_stream.finish().await.unwrap();

        let mut buffer = [0; 64];
        let bytes_read = receive_stream.read(&mut buffer).await.unwrap().unwrap();

        assert_eq!(
            &buffer[..bytes_read],
            b"Hello world!",
            "The server should have echoed the message back"
        );
    }
}

/// Echoes each chunk back as it arrives rather than waiting for the client to close the
/// stream, so a long lived stream (an audio feed, say) doesn't sit buffered in the server.
async fn echo_stream(mut send_stream: SendStream, mut receive_stream: RecvStream) {
    let mut buffer = vec![0; 65536].into_boxed_slice();

    loop {
        match receive_stream.read(&mut buffer).await {
            Ok(Some(bytes_read)) => {
                if let Err(error) = send_stream.write_all(&buffer[..bytes_read]).await {
                    println!("WebTransport stream write failed: {error}");
                    return;
                }
            }
            Ok(None) => {
                if let Err(error) = send_stream.finish().await {
                    println!("WebTransport stream finish failed: {error}");
                }
                return;
            }
            Err(error) => {
                println!("WebTransport stream read failed: {error}");
                return;
            }
        }
    }
}
