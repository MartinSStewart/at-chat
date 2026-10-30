//! Passes a file too large to store from the device it was attached on straight
//! to whoever is downloading it, without keeping any of it.
//!
//! When someone presses a peer to peer attachment, Lamdera makes up a transfer id
//! and hands the same signed url to both ends. The uploader's browser POSTs the
//! whole file to `/file/p2p/{transfer_id}` and the downloader's browser GETs it.
//! Whichever arrives first waits for the other, and then the POST body is streamed
//! into the GET response as it arrives. Nothing is buffered beyond what is in
//! flight, so a downloader who reads slowly slows the uploader down rather than
//! filling memory.
//!
//! The signature stops anyone using this as a relay for files that were never
//! attached to a message. Nothing else is checked here: Lamdera already decided
//! the downloader can see the file before it signed the url.

use crate::AppState;
use axum::Extension;
use axum::body::Body;
use axum::extract::{Path, Query, Request, State};
use axum::http::StatusCode;
use axum::response::Response;
use futures_util::StreamExt;
use serde::Deserialize;
use sha2::{Digest, Sha256};
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use std::time::{Duration, SystemTime};
use subtle::ConstantTimeEq;
use tokio::sync::oneshot;

/// Transfers where one side has arrived and is waiting for the other.
pub type Transfers = Arc<Mutex<HashMap<String, Waiting>>>;

pub fn transfers() -> Transfers {
    Arc::new(Mutex::new(HashMap::new()))
}

/// The uploader's tab is told about the transfer at the same moment as the
/// downloader, so either one normally turns up within a second or two of the
/// other. Anything much later means that side has gone.
const RENDEZVOUS_TIMEOUT: Duration = Duration::from_secs(30);

pub enum Waiting {
    Downloader(oneshot::Sender<Upload>),
    Uploader(Upload),
}

/// The uploader's request body, and where to say how it went once the downloader
/// has read it.
pub struct Upload {
    body: Body,
    finished: oneshot::Sender<Result<(), String>>,
}

#[derive(Deserialize)]
pub struct TransferQuery {
    size: u64,
    expires: u64,
    token: String,
    name: Option<String>,
}

/// Has to match `PeerToPeer.transferToken` on the Elm side.
fn transfer_token(secret_key: &[u8], transfer_id: &str, size: u64, expires: u64) -> String {
    let mut hasher = Sha256::new();
    hasher.update(secret_key);
    hasher.update(format!(":p2p:{transfer_id}:{size}:{expires}").as_bytes());
    hasher
        .finalize()
        .iter()
        .map(|byte| format!("{byte:02x}"))
        .collect()
}

fn is_valid_transfer_id(transfer_id: &str) -> bool {
    !transfer_id.is_empty()
        && transfer_id.len() <= 64
        && transfer_id.chars().all(|x| x.is_ascii_hexdigit())
}

fn now_millis() -> u64 {
    SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .map(|duration| duration.as_millis() as u64)
        .unwrap_or(0)
}

fn check_transfer(
    secret_key: &[u8],
    transfer_id: &str,
    query: &TransferQuery,
    now: u64,
) -> Result<(), &'static str> {
    if !is_valid_transfer_id(transfer_id) {
        return Err("Invalid transfer");
    }
    let expected = transfer_token(secret_key, transfer_id, query.size, query.expires);
    if !bool::from(expected.as_bytes().ct_eq(query.token.as_bytes())) {
        return Err("Invalid transfer");
    }
    if now > query.expires {
        return Err("This download link has expired, press the file again");
    }
    Ok(())
}

/// The upload is cross origin while developing, and the uploader's tab wants to
/// read the answer.
fn plain_response(status: StatusCode, message: impl Into<String>) -> Response<Body> {
    Response::builder()
        .status(status)
        .header("Access-Control-Allow-Origin", crate::allowed_origin())
        .header("Access-Control-Allow-Credentials", "true")
        .header("Content-Type", "text/plain")
        .body(Body::from(message.into()))
        .unwrap()
}

/// The uploader's side. Answers once the downloader has the whole file, or as
/// soon as it's clear they won't get it.
pub async fn upload_endpoint(
    Path(transfer_id): Path<String>,
    Query(query): Query<TransferQuery>,
    State(state): State<Arc<Mutex<AppState>>>,
    Extension(transfers): Extension<Transfers>,
    request: Request,
) -> Response<Body> {
    let secret_key: Vec<u8> = state.lock().unwrap().secret_key.clone();
    if let Err(message) = check_transfer(&secret_key, &transfer_id, &query, now_millis()) {
        return plain_response(StatusCode::FORBIDDEN, message);
    }

    let (finished_sender, finished_receiver) = oneshot::channel();
    let mut upload = Some(Upload {
        body: request.into_body(),
        finished: finished_sender,
    });

    let waiting_downloader: Option<oneshot::Sender<Upload>> = {
        let mut transfers2 = transfers.lock().unwrap();
        match transfers2.remove(&transfer_id) {
            Some(Waiting::Downloader(sender)) => Some(sender),
            Some(Waiting::Uploader(other)) => {
                transfers2.insert(transfer_id.clone(), Waiting::Uploader(other));
                return plain_response(StatusCode::CONFLICT, "Already being uploaded");
            }
            None => {
                if let Some(upload2) = upload.take() {
                    transfers2.insert(transfer_id.clone(), Waiting::Uploader(upload2));
                }
                None
            }
        }
    };

    match waiting_downloader {
        Some(sender) => {
            if let Some(upload2) = upload
                && sender.send(upload2).is_err()
            {
                return plain_response(StatusCode::GONE, "The downloader left");
            }
        }
        None => {
            // The upload is in the map now, so a downloader arriving takes it and
            // the finished channel answers below. If nobody comes, it is taken back
            // out here, which drops the body and closes the connection.
            let transfers3 = transfers.clone();
            let transfer_id2 = transfer_id.clone();
            tokio::spawn(async move {
                tokio::time::sleep(RENDEZVOUS_TIMEOUT).await;
                let mut transfers4 = transfers3.lock().unwrap();
                if let Some(Waiting::Uploader(_)) = transfers4.get(&transfer_id2) {
                    transfers4.remove(&transfer_id2);
                }
            });
        }
    }

    match finished_receiver.await {
        Ok(Ok(())) => plain_response(StatusCode::OK, "Sent"),
        Ok(Err(message)) => plain_response(StatusCode::BAD_REQUEST, message),
        Err(_) => plain_response(StatusCode::GONE, "The downloader didn't get the whole file"),
    }
}

/// The downloader's side. Waits for the uploader, then streams their upload back
/// as an ordinary file download.
pub async fn download_endpoint(
    Path(transfer_id): Path<String>,
    Query(query): Query<TransferQuery>,
    State(state): State<Arc<Mutex<AppState>>>,
    Extension(transfers): Extension<Transfers>,
) -> Response<Body> {
    let secret_key: Vec<u8> = state.lock().unwrap().secret_key.clone();
    if let Err(message) = check_transfer(&secret_key, &transfer_id, &query, now_millis()) {
        return plain_response(StatusCode::FORBIDDEN, message);
    }

    let (sender, receiver) = oneshot::channel();
    let waiting_upload: Option<Upload> = {
        let mut transfers2 = transfers.lock().unwrap();
        match transfers2.remove(&transfer_id) {
            Some(Waiting::Uploader(upload)) => Some(upload),
            Some(Waiting::Downloader(other)) => {
                // Someone already opened this link. Leave them be.
                transfers2.insert(transfer_id.clone(), Waiting::Downloader(other));
                return plain_response(StatusCode::CONFLICT, "Already being downloaded");
            }
            None => {
                transfers2.insert(transfer_id.clone(), Waiting::Downloader(sender));
                None
            }
        }
    };

    let upload: Upload = match waiting_upload {
        Some(upload) => upload,
        None => match tokio::time::timeout(RENDEZVOUS_TIMEOUT, receiver).await {
            Ok(Ok(upload)) => upload,
            _ => {
                transfers.lock().unwrap().remove(&transfer_id);
                return plain_response(
                    StatusCode::GATEWAY_TIMEOUT,
                    "The uploader's device didn't start sending the file",
                );
            }
        },
    };

    println!(
        "Peer to peer transfer {transfer_id} started, {} bytes",
        query.size
    );

    let relay = Relay {
        transfer_id,
        incoming: upload.body.into_data_stream(),
        sent: 0,
        size: query.size,
        finished: Some(upload.finished),
    };

    let body = futures_util::stream::unfold(relay, |mut relay| async move {
        relay.finished.as_ref()?;

        match relay.incoming.next().await {
            Some(Ok(bytes)) => {
                relay.sent += bytes.len() as u64;
                if relay.sent > relay.size {
                    relay.finish(Err(String::from("The file is larger than it said it was")));
                    Some((Err(std::io::Error::other("Too many bytes")), relay))
                } else {
                    // The response stops asking for more once it has sent as many
                    // bytes as its Content-Length, so this is the last chance to
                    // say it went through.
                    if relay.sent == relay.size {
                        println!(
                            "Peer to peer transfer {} finished, {} bytes",
                            relay.transfer_id, relay.sent
                        );
                        relay.finish(Ok(()));
                    }
                    Some((Ok(bytes), relay))
                }
            }
            Some(Err(error)) => {
                relay.finish(Err(String::from("The upload stopped partway")));
                Some((Err(std::io::Error::other(error)), relay))
            }
            None => {
                relay.finish(Err(String::from("The file is smaller than it said it was")));
                Some((Err(std::io::Error::other("Too few bytes")), relay))
            }
        }
    });

    Response::builder()
        .status(StatusCode::OK)
        .header("Content-Type", "application/octet-stream")
        .header("Content-Length", query.size)
        .header(
            "Content-Disposition",
            content_disposition(query.name.as_deref().unwrap_or("download")),
        )
        .header("Cache-Control", "no-store")
        .header("X-Content-Type-Options", "nosniff")
        .body(Body::from_stream(body))
        .unwrap()
}

/// Lives as long as the download does. Dropping it before the end, which is what
/// happens when the downloader goes away, drops the finished channel too, and the
/// uploader's request is answered with that.
struct Relay {
    transfer_id: String,
    incoming: axum::body::BodyDataStream,
    sent: u64,
    size: u64,
    finished: Option<oneshot::Sender<Result<(), String>>>,
}

impl Relay {
    fn finish(&mut self, result: Result<(), String>) {
        if let Some(finished) = self.finished.take() {
            if let Err(message) = &result {
                println!(
                    "Peer to peer transfer {} failed after {} of {} bytes: {message}",
                    self.transfer_id, self.sent, self.size
                );
            }
            let _ = finished.send(result);
        }
    }
}

impl Drop for Relay {
    fn drop(&mut self) {
        if self.finished.is_some() {
            println!(
                "Peer to peer transfer {} stopped after {} of {} bytes",
                self.transfer_id, self.sent, self.size
            );
        }
    }
}

/// Any name works in `filename*`, but only one in plain ASCII without quotes or
/// backslashes can also go in `filename` for browsers that ignore the other.
fn content_disposition(name: &str) -> String {
    let encoded: String = name
        .bytes()
        .map(|byte| {
            if byte.is_ascii_alphanumeric() || b"!#$&+-.^_`|~".contains(&byte) {
                (byte as char).to_string()
            } else {
                format!("%{byte:02X}")
            }
        })
        .collect();
    let is_plain = name
        .chars()
        .all(|x| x == ' ' || (x.is_ascii_graphic() && x != '"' && x != '\\'));
    if is_plain {
        format!("attachment; filename=\"{name}\"; filename*=UTF-8''{encoded}")
    } else {
        format!("attachment; filename*=UTF-8''{encoded}")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::Router;
    use axum::extract::DefaultBodyLimit;
    use axum::routing::get;

    async fn test_server() -> String {
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0")
            .await
            .expect("failed to bind test server");
        let base = format!("http://{}", listener.local_addr().unwrap());
        let state = Arc::new(Mutex::new(AppState {
            secret_key: b"secret".to_vec(),
        }));
        let router = Router::new()
            .route(
                "/file/p2p/{transfer_id}",
                get(download_endpoint).post(upload_endpoint),
            )
            .layer(Extension(transfers()))
            .layer(DefaultBodyLimit::max(1024))
            .with_state(state);
        tokio::spawn(async move {
            let _ = axum::serve(listener, router).await;
        });
        base
    }

    fn transfer_url(base: &str, transfer_id: &str, size: u64) -> String {
        let expires = now_millis() + 60_000;
        format!(
            "{base}/file/p2p/{transfer_id}?size={size}&expires={expires}&token={}&name=big%20file.bin",
            transfer_token(b"secret", transfer_id, size, expires)
        )
    }

    async fn transfer(upload_first: bool) {
        let base = test_server().await;
        let file: Vec<u8> = (0..5_000_000u32).map(|x| (x % 251) as u8).collect();
        let url = transfer_url(&base, "abc123", file.len() as u64);
        let client = reqwest::Client::new();

        let upload = {
            let client2 = client.clone();
            let url2 = url.clone();
            let file2 = file.clone();
            tokio::spawn(async move { client2.post(url2).body(file2).send().await })
        };
        if upload_first {
            tokio::time::sleep(Duration::from_millis(200)).await;
        }
        let download = client.get(&url).send().await.expect("download failed");

        assert_eq!(download.status(), StatusCode::OK);
        assert_eq!(
            download.headers()["content-disposition"],
            "attachment; filename=\"big file.bin\"; filename*=UTF-8''big%20file.bin"
        );
        let downloaded = download.bytes().await.expect("download body failed");
        assert!(
            downloaded.as_ref() == file.as_slice(),
            "the download should be the uploaded file"
        );

        let upload_response = upload.await.unwrap().expect("upload failed");
        assert_eq!(upload_response.status(), StatusCode::OK);
    }

    #[tokio::test]
    async fn passes_a_file_through_when_the_downloader_arrives_first() {
        let base = test_server().await;
        let file: Vec<u8> = vec![7; 3_000_000];
        let url = transfer_url(&base, "def456", file.len() as u64);
        let client = reqwest::Client::new();

        let download = {
            let client2 = client.clone();
            let url2 = url.clone();
            tokio::spawn(async move { client2.get(url2).send().await?.bytes().await })
        };
        tokio::time::sleep(Duration::from_millis(200)).await;
        let upload_response = client
            .post(&url)
            .body(file.clone())
            .send()
            .await
            .expect("upload failed");

        assert_eq!(upload_response.status(), StatusCode::OK);
        let downloaded = download.await.unwrap().expect("download failed");
        assert!(downloaded.as_ref() == file.as_slice());
    }

    #[tokio::test]
    async fn passes_a_file_through_when_the_uploader_arrives_first() {
        transfer(true).await;
    }

    #[tokio::test]
    async fn passes_a_file_through_when_both_arrive_together() {
        transfer(false).await;
    }

    #[tokio::test]
    async fn tells_the_uploader_when_the_size_is_wrong() {
        let base = test_server().await;
        let url = transfer_url(&base, "fed789", 1000);
        let client = reqwest::Client::new();

        let upload = {
            let client2 = client.clone();
            let url2 = url.clone();
            tokio::spawn(async move { client2.post(url2).body(vec![1u8; 2000]).send().await })
        };
        let downloaded = match client.get(&url).send().await {
            Ok(download) => download.bytes().await.is_ok(),
            Err(_) => false,
        };
        assert!(!downloaded, "the download should break off");
        assert_ne!(
            upload.await.unwrap().expect("upload failed").status(),
            StatusCode::OK
        );
    }

    #[tokio::test]
    async fn refuses_a_link_with_a_bad_token() {
        let base = test_server().await;
        let response = reqwest::Client::new()
            .get(format!(
                "{base}/file/p2p/abc?size=10&expires=99999999999999&token=00"
            ))
            .send()
            .await
            .expect("request failed");
        assert_eq!(response.status(), StatusCode::FORBIDDEN);
    }

    #[test]
    fn token_matches_elm() {
        // Worked out with Sha256.sha256 "secret:p2p:abc123:1000:2000" in Elm.
        assert_eq!(
            transfer_token(b"secret", "abc123", 1000, 2000),
            "9d7e112068d366c09bfe692ab8e4ce3b34144552c1dc31a47b1874c4f4108513"
        );
    }

    #[test]
    fn rejects_a_wrong_token() {
        let query = TransferQuery {
            size: 1000,
            expires: 2000,
            token: String::from("00"),
            name: None,
        };
        assert!(check_transfer(b"secret", "abc123", &query, 1000).is_err());
    }

    #[test]
    fn rejects_an_expired_link() {
        let query = TransferQuery {
            size: 1000,
            expires: 2000,
            token: transfer_token(b"secret", "abc123", 1000, 2000),
            name: None,
        };
        assert!(check_transfer(b"secret", "abc123", &query, 1999).is_ok());
        assert!(check_transfer(b"secret", "abc123", &query, 2001).is_err());
    }

    #[test]
    fn rejects_a_transfer_id_that_is_not_hex() {
        let query = TransferQuery {
            size: 1000,
            expires: 2000,
            token: transfer_token(b"secret", "a/b", 1000, 2000),
            name: None,
        };
        assert!(check_transfer(b"secret", "a/b", &query, 1000).is_err());
    }

    #[test]
    fn content_disposition_keeps_odd_names_out_of_the_quoted_part() {
        assert_eq!(
            content_disposition("big file.zip"),
            "attachment; filename=\"big file.zip\"; filename*=UTF-8''big%20file.zip"
        );
        assert_eq!(
            content_disposition("a\"b.zip"),
            "attachment; filename*=UTF-8''a%22b.zip"
        );
        assert_eq!(
            content_disposition("ä.zip"),
            "attachment; filename*=UTF-8''%C3%A4.zip"
        );
    }
}
