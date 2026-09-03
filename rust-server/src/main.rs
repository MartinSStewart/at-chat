use axum::body::Body;
use axum::response::Response;
use axum::{Json, RequestExt};
use axum::{
    Router,
    body::Bytes,
    extract::{DefaultBodyLimit, Path, Request, State},
    http::{StatusCode, Uri},
    middleware::Next,
    routing::get,
    routing::post,
};

use chrono;
use http::HeaderMap;
use image::metadata::Orientation;
use image::{self, GenericImageView, ImageFormat, ImageReader};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha224};
use std::fs;
use std::str::FromStr;
use web_push::SubscriptionInfo;
use webpage::HTML;
mod content_types;
mod video;
mod websocket;
use rand::RngExt;
use std::sync::Arc;
use std::sync::Mutex;
use std::time::Duration;
use std::time::SystemTime;
use subtle::ConstantTimeEq;
#[tokio::main]
async fn main() {
    // secret.txt should match Env.secretKey
    match fs::read_to_string(SERVER_SECRET_PATH.to_string()) {
        Ok(secret_key) => {
            let state = Arc::new(Mutex::new(AppState {
                secret_key: secret_key.trim().as_bytes().to_vec(),
            }));

            let rooms = websocket::rooms();

            let app = Router::new()
                .route(
                    "/file/internal/embed",
                    post(post_embed).options(options_endpoint),
                )
                .route(
                    "/file/internal/upload-backup/{filename}",
                    post(post_backup_endpoint).options(options_endpoint),
                )
                .route(
                    "/file/internal/regenerate-server-secret",
                    post(regenerate_server_secret_endpoint).options(options_endpoint),
                )
                .route(
                    "/file/upload",
                    post(upload_endpoint).options(options_endpoint),
                )
                .route(
                    "/file/upload-encrypted",
                    post(upload_encrypted_endpoint).options(options_endpoint),
                )
                .route(
                    "/file/internal/upload-url",
                    post(upload_url_endpoint).options(options_endpoint),
                )
                .route(
                    "/file/internal/push-notification",
                    post(push_notification_endpoint).options(options_endpoint),
                )
                .route(
                    "/file/internal/custom-request",
                    post(custom_request_endpoint).options(options_endpoint),
                )
                .route(
                    "/file/discord-sticker/{sticker_id}",
                    get(discord_sticker_endpoint).options(options_endpoint),
                )
                .route("/file/internal/vapid", get(vapid_endpoint))
                .route("/file/websocket", get(websocket::websocket_endpoint))
                .route("/file/websocket/{room_id}", get(websocket::room_endpoint))
                .route("/file/{content_type}/{filename}", get(get_file_endpoint))
                .route("/file/t/{filename}", get(get_file_thumbnail_endpoint))
                .layer(axum::Extension(rooms))
                .layer(DefaultBodyLimit::max(100 * 1024 * 1024))
                .layer(axum::middleware::from_fn_with_state(
                    state.clone(),
                    require_internal_secret,
                ))
                .layer(axum::middleware::from_fn(require_allowed_origin))
                .fallback(fallback)
                .with_state(state);

            match tokio::net::TcpListener::bind("0.0.0.0:3000").await {
                Ok(listener) => {
                    let _ = axum::serve(listener, app).await;
                }
                Err(error) => {
                    println!("Server didn't start: {error}");
                }
            };
        }
        Err(error) => {
            println!("Server didn't start due to {SERVER_SECRET_PATH} not getting loaded: {error}");
        }
    }
}

const SERVER_SECRET_PATH: &str = "./var/lib/atchat/secret.txt";

#[derive(Clone)]
pub struct AppState {
    pub secret_key: Vec<u8>,
}

async fn require_internal_secret(
    State(state): State<Arc<Mutex<AppState>>>,
    req: Request,
    next: Next,
) -> Response<Body> {
    let path = req.uri().path();

    if path.to_string().starts_with("/file/internal/")
        && (req.method() != axum::http::Method::OPTIONS)
    {
        let provided = req
            .headers()
            .get("x-secret-key")
            .and_then(|v| v.to_str().ok());

        match provided {
            Some(token) => {
                let authorized = token
                    .as_bytes()
                    .to_vec()
                    .ct_eq(&state.lock().unwrap().secret_key)
                    .into();
                if authorized {
                    next.run(req).await
                } else {
                    Response::builder()
                        .status(StatusCode::FORBIDDEN)
                        .body(Body::from("Invalid secret key"))
                        .unwrap()
                }
            }
            None => Response::builder()
                .status(StatusCode::FORBIDDEN)
                .body(Body::from("Missing x-secret-key"))
                .unwrap(),
        }
    } else {
        next.run(req).await
    }
}

/// Now that the `sid` cookie is what authorises an upload, the browser attaches
/// it to any request a third party site makes to us as well. CORS on its own is
/// not enough to stop that: a POST with a `text/plain` body is not preflighted,
/// so the request is sent and only the response is withheld — by which time the
/// file has been uploaded. Checking `Origin` rejects it before any work happens.
///
/// A request with no `Origin` at all did not come from a browser, so there is no
/// ambient cookie for it to have abused, and it is left alone.
async fn require_allowed_origin(req: Request, next: Next) -> Response<Body> {
    match req.headers().get("origin").and_then(|v| v.to_str().ok()) {
        Some(origin) if origin != allowed_origin() => Response::builder()
            .status(StatusCode::FORBIDDEN)
            .body(Body::from("Origin not allowed"))
            .unwrap(),
        _ => next.run(req).await,
    }
}

async fn options_endpoint() -> Response<String> {
    response_with_headers(StatusCode::OK, String::from("OK"))
}

fn filepath(hash: &str) -> String {
    format!("./var/lib/atchat/storage/{hash}")
}

fn thumbnail_filepath(hash: &str) -> String {
    format!("./var/lib/atchat/storage/{hash}_thumbnail")
}


enum FetchedContent {
    Image(Vec<u8>),
    Html(String),
}

async fn fetch_content(client: &reqwest::Client, url: &str) -> Option<FetchedContent> {
    let response: reqwest::Response = client.get(url).send().await.ok()?;

    let is_image = response
        .headers()
        .get(reqwest::header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .map(|v| v.trim().to_ascii_lowercase().starts_with("image/"))
        .unwrap_or(false);

    let buf: Vec<u8> = response.bytes().await.ok()?.to_vec();

    if is_image {
        if buf.len() < 10 * 1024 * 1024 {
            Some(FetchedContent::Image(buf))
        } else {
            None
        }
    } else if buf.len() < 1024 * 1024 {
        Some(FetchedContent::Html(
            String::from_utf8_lossy(&buf).into_owned(),
        ))
    }
    else {
        None
    }
}

fn image_format_name(format: ImageFormat) -> Option<String> {
    match format {
        ImageFormat::Png => Some(String::from("Png")),
        ImageFormat::Jpeg => Some(String::from("Jpeg")),
        ImageFormat::Gif => Some(String::from("Gif")),
        ImageFormat::WebP => Some(String::from("WebP")),
        ImageFormat::Pnm => Some(String::from("Pnm")),
        ImageFormat::Tiff => Some(String::from("Tiff")),
        ImageFormat::Tga => Some(String::from("Tga")),
        ImageFormat::Dds => Some(String::from("Dds")),
        ImageFormat::Bmp => Some(String::from("Bmp")),
        ImageFormat::Ico => Some(String::from("Ico")),
        ImageFormat::Hdr => Some(String::from("Hdr")),
        ImageFormat::OpenExr => Some(String::from("OpenExr")),
        ImageFormat::Farbfeld => Some(String::from("Farbfeld")),
        ImageFormat::Avif => Some(String::from("Avif")),
        ImageFormat::Qoi => Some(String::from("Qoi")),
        _ => None,
    }
}

fn image_data_from_bytes(url: &str, bytes: &[u8]) -> Option<ImageData> {
    let reader = ImageReader::new(std::io::Cursor::new(bytes));

    match reader
        .with_guessed_format()
        .map(|a| (a.format(), a.decode()))
    {
        Ok((Some(format), Ok(image))) => {
            let (width, height) = image.dimensions();
            Some(ImageData {
                url: url.to_string(),
                width,
                height,
                format: image_format_name(format),
            })
        }
        _ => None,
    }
}

// Parse already-fetched HTML without letting a parse failure take down the server.
fn parse_html_safe(body: String, url: String) -> Option<HTML> {
    std::thread::Builder::new()
        .stack_size(1024 * 1024 * 1024) // 1 GiB (lazily committed) headroom for recursion
        .spawn(move || {
            std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
                HTML::from_string(body, Some(url)).ok()
            }))
            .ok()
            .flatten()
        })
        .ok()?
        .join()
        .ok()
        .flatten()
}

async fn build_embed(client: &reqwest::Client, url: &str) -> Option<EmbedResponse> {
    let html = match fetch_content(client, url).await? {
        // The link points straight at an image: skip HTML parsing entirely and
        // build the embed from the image itself.
        FetchedContent::Image(bytes) => {
            return Some(EmbedResponse {
                title: None,
                description: None,
                image: image_data_from_bytes(url, &bytes),
                created_at: None,
            });
        }
        FetchedContent::Html(body) => parse_html_safe(body, url.to_string())?,
    };

    // Follow a single meta-refresh redirect, matching the previous behaviour.
    let html = match (html.meta.len(), html.meta.get("refresh")) {
        (1, Some(refresh)) => {
            let redirect_url = refresh.split('=').skip(1).collect::<Vec<_>>().join("=");
            match fetch_content(client, &redirect_url).await {
                Some(FetchedContent::Html(body)) => {
                    parse_html_safe(body, redirect_url).unwrap_or(html)
                }
                _ => html,
            }
        }
        _ => html,
    };

    let image = match html.meta.get("og:image") {
        Some(image_url) => match fetch_content(client, image_url).await {
            Some(FetchedContent::Image(bytes)) => image_data_from_bytes(image_url, &bytes),
            _ => None,
        },
        None => None,
    };

    Some(EmbedResponse {
        title: html.meta.get("og:title").cloned(),
        description: html.meta.get("og:description").cloned(),
        image,
        created_at: html
            .meta
            .get("article:published_time")
            .and_then(|text| chrono::DateTime::parse_from_rfc3339(text).ok())
            .map(|date| date.timestamp()),
    })
}

async fn post_embed(Json(EmbedRequest { url }): Json<EmbedRequest>) -> Response<String> {
    let empty = EmbedResponse {
        title: None,
        description: None,
        image: None,
        created_at: None,
    };

    let response = match reqwest::Client::builder()
        .timeout(Duration::from_secs(15))
        .build()
    {
        Ok(client) => build_embed(&client, &url).await.unwrap_or(empty),
        Err(_) => empty,
    };

    response_with_headers(
        StatusCode::OK,
        serde_json::to_string::<EmbedResponse>(&response).unwrap(),
    )
}

async fn vapid_endpoint(_request: Request) -> Response<String> {
    match vapid::Key::generate() {
        Ok(key) => response_with_headers(
            StatusCode::OK,
            format!("{:?},{:?}", key.to_public_raw(), &key.to_private_raw()),
        ),
        Err(_) => response_with_headers(
            StatusCode::BAD_REQUEST,
            String::from("Failed to generate keys"),
        ),
    }
}

fn vec_to_headermap(
    headers: Vec<Header>,
) -> Result<HeaderMap<http::HeaderValue>, Box<dyn std::error::Error>> {
    let mut header_map = HeaderMap::new();

    for header in headers {
        let header_name = http::HeaderName::from_str(&header.key)?;
        let header_value = http::HeaderValue::from_str(&header.value)?;

        header_map.insert(header_name, header_value);
    }

    Ok(header_map)
}

const SERVER_BACKUPS_PATH: &str = "./var/lib/atchat/backups/";
const BUCKET_BACKUPS_PATH: &str = "./var/lib/atchat/storage/backups/";

fn create_dir_if_missing(path: String) {
    match fs::exists(&path) {
        Ok(true) => (),
        _ => {
            let _ = fs::create_dir(&path);
        }
    }
}

const BACKUP_MAX_AGE: Duration = Duration::from_secs(30 * 24 * 60 * 60);

fn remove_old_backups(dir: String) {
    let now = SystemTime::now();

    match fs::read_dir(&dir) {
        Ok(entries) => {
            for entry in entries {
                match entry {
                    Ok(entry2) => match (entry2.metadata(), entry2.file_name().to_str()) {
                        (Ok(metadata), Some(filename)) => {
                            match (metadata.is_file(), metadata.created()) {
                                (true, Ok(time)) => {
                                    let should_delete = match now.duration_since(time) {
                                        Ok(duration) => {
                                            duration > BACKUP_MAX_AGE
                                                && filename.starts_with("backend-export-")
                                        }
                                        Err(_) => false,
                                    };
                                    if should_delete {
                                        let _ = fs::remove_file(entry2.path());
                                    }
                                }
                                _ => {}
                            }
                        }
                        _ => {}
                    },
                    Err(_) => {}
                }
            }
        }
        Err(_) => {}
    }
}

async fn post_backup_endpoint(Path(filename): Path<String>, body: Bytes) -> Response<String> {
    create_dir_if_missing(SERVER_BACKUPS_PATH.to_string());
    create_dir_if_missing(BUCKET_BACKUPS_PATH.to_string());

    remove_old_backups(SERVER_BACKUPS_PATH.to_string());
    remove_old_backups(BUCKET_BACKUPS_PATH.to_string());

    // The first path is on the main server and the second path is the S3 bucket. We write to both to improve the odds that we don't lose all backups
    let write_a = fs::write(String::from(SERVER_BACKUPS_PATH) + &filename, &body);
    let write_b = fs::write(String::from(BUCKET_BACKUPS_PATH) + &filename, &body);

    match (write_a, write_b) {
        (Ok(_), Ok(_)) => response_with_headers(StatusCode::OK, ""),
        (Err(error), Ok(_)) => response_with_headers(
            StatusCode::BAD_REQUEST,
            format!("First write failed\n{:?}", error),
        ),
        (Ok(_), Err(error)) => response_with_headers(
            StatusCode::BAD_REQUEST,
            format!("Second write failed\n{:?}", error),
        ),
        (Err(error_a), Err(error_b)) => response_with_headers(
            StatusCode::BAD_REQUEST,
            format!("Both file writes failed\n{:?}\n{:?}", error_a, error_b),
        ),
    }
}

async fn regenerate_server_secret_endpoint(state: State<Arc<Mutex<AppState>>>) -> Response<String> {
    let mut rng = rand::rng();
    let random_string: String = (0..64)
        .map(|_| format!("{}", (rng.random_range(0..10))))
        .collect();
    match fs::write(String::from(SERVER_SECRET_PATH), &random_string) {
        Ok(_) => {
            let mut state2 = state.lock().unwrap();
            state2.secret_key = random_string.clone().into();
            response_with_headers(StatusCode::OK, random_string)
        }
        Err(error) => response_with_headers(
            StatusCode::BAD_REQUEST,
            format!("Write failed\n{:?}", error),
        ),
    }
}

async fn custom_request_endpoint(
    Json(CustomRequest {
        method,
        url,
        headers,
        body,
    }): Json<CustomRequest>,
) -> Response<String> {
    let headers2 = match vec_to_headermap(headers) {
        Ok(ok) => ok,
        Err(error) => {
            return response_with_headers(StatusCode::BAD_REQUEST, format!("Error 1: {error:?}"));
        }
    };

    let client = reqwest::Client::new();

    let request = match method.as_str() {
        "GET" => client.get(url),
        "POST" => client.post(url),
        "PUT" => client.put(url),
        "PATCH" => client.patch(url),
        "DELETE" => client.delete(url),
        "HEAD" => client.head(url),
        _ => {
            return response_with_headers(
                StatusCode::BAD_REQUEST,
                format!("Invalid method: {method}"),
            );
        }
    };

    let request2 = request.headers(headers2);

    let request3 = match body {
        Some(body2) => request2.body(body2),
        None => request2,
    };

    match request3.send().await {
        Ok(response) => {
            let status = response.status();
            let response_text = match response.text().await {
                Ok(text) => text,
                Err(error) => {
                    return response_with_headers(
                        StatusCode::BAD_REQUEST,
                        format!("Error 2: {error:?}"),
                    );
                }
            };

            response_with_headers(status, response_text)
        }
        Err(error) => {
            response_with_headers(StatusCode::BAD_REQUEST, format!("Error 3:  {error:?}"))
        }
    }
}

async fn push_notification_endpoint(
    Json(PushNotification {
        endpoint,
        p256dh,
        auth,
        private_key,
        title,
        body,
        icon,
        navigate,
        data,
        mutable,
        is_declarative,
    }): Json<PushNotification>,
) -> Response<String> {
    // You would likely get this by deserializing a browser `pushSubscription` object.
    let subscription_info: SubscriptionInfo = SubscriptionInfo::new(endpoint, p256dh, auth);

    let content: Notification<String> =
        Notification::new(title, navigate, Some(body), Some(icon), data);

    let key = match web_push::VapidSignatureBuilder::from_base64(&private_key, &subscription_info) {
        Ok(key2) => key2,
        Err(_) => return response_with_headers(StatusCode::BAD_REQUEST, String::from("Error 1")),
    };

    let content = match content.to_payload(is_declarative, mutable) {
        Ok(content2) => content2,
        Err(_) => return response_with_headers(StatusCode::BAD_REQUEST, String::from("Error 2")),
    };

    let sig_builder = match key.build() {
        Ok(sig_builder2) => sig_builder2,
        Err(_) => return response_with_headers(StatusCode::BAD_REQUEST, String::from("Error 3")),
    };

    let mut builder: web_push::WebPushMessageBuilder<'_> =
        web_push::WebPushMessageBuilder::new(&subscription_info);

    builder.set_payload(web_push::ContentEncoding::Aes128Gcm, &content);
    builder.set_vapid_signature(sig_builder);

    let client = match web_push::IsahcWebPushClient::new() {
        Ok(client2) => client2,
        Err(_) => return response_with_headers(StatusCode::BAD_REQUEST, String::from("Error 4")),
    };

    let builder = match builder.build() {
        Ok(builder2) => builder2,
        Err(_) => return response_with_headers(StatusCode::BAD_REQUEST, String::from("Error 5")),
    };

    match web_push::WebPushClient::send(&client, builder).await {
        Ok(()) => response_with_headers(StatusCode::OK, ""),
        Err(error) => response_with_headers(
            StatusCode::BAD_REQUEST,
            match error {
                web_push::WebPushError::Unspecified => String::from("Error 6"),
                web_push::WebPushError::Unauthorized(error_info) => format!(
                    "Error 7. Error: {:?} Message: {:?}",
                    &error_info.error, &error_info.message
                ),
                web_push::WebPushError::BadRequest(error_info) => format!(
                    "Bad request. Error: {:?} Message: {:?}",
                    &error_info.error, &error_info.message
                ),
                web_push::WebPushError::ServerError {
                    retry_after: _,
                    info: _,
                } => String::from("Error 8"),
                web_push::WebPushError::NotImplemented(error_info) => format!(
                    "Error 9. Error: {:?} Message: {:?}",
                    &error_info.error, &error_info.message
                ),
                web_push::WebPushError::InvalidUri => String::from("Error 10"),
                web_push::WebPushError::EndpointNotValid(error_info) => format!(
                    "Error 11. Error: {:?} Message: {:?}",
                    &error_info.error, &error_info.message
                ),
                web_push::WebPushError::EndpointNotFound(error_info) => format!(
                    "Error 12. Error: {:?} Message: {:?}",
                    &error_info.error, &error_info.message
                ),
                web_push::WebPushError::PayloadTooLarge => String::from("Error 13"),
                web_push::WebPushError::Io(_) => String::from("Error 14"),
                web_push::WebPushError::InvalidPackageName => String::from("Error 15"),
                web_push::WebPushError::InvalidTtl => String::from("Error 16"),
                web_push::WebPushError::InvalidTopic => String::from("Error 17"),
                web_push::WebPushError::MissingCryptoKeys => String::from("Error 18"),
                web_push::WebPushError::InvalidCryptoKeys => String::from("Error 19"),
                web_push::WebPushError::InvalidResponse => String::from("Error 20"),
                web_push::WebPushError::InvalidClaims => String::from("Error 21"),
                web_push::WebPushError::ResponseTooLarge => String::from("Error 22"),
                web_push::WebPushError::Other(other) => {
                    format!("Error 23: {:?}", &other.message)
                }
            },
        ),
    }
}

/// Who an upload is being done on behalf of.
enum Uploader {
    /// A browser. The session id came out of the `sid` cookie, which the browser
    /// attaches itself and page scripts cannot read in production, so unlike the
    /// session id hash it used to send it is not something a caller can choose.
    Session(String),
    /// Our own backend, which has no cookie to be identified by and proves who
    /// it is with the server secret instead.
    Backend,
}

/// Reads the `sid` cookie. Two kinds of value are refused rather than returned:
///
/// A value containing a comma, because the session id is passed to Lamdera as
/// one comma separated field among several, and a comma in it would let the
/// caller write the fields either side.
///
/// An empty value, because an empty session id is how `is_file_upload_allowed`
/// tells Lamdera the upload was the backend's own. A caller sending `sid=` would
/// otherwise be taken for the backend and allowed to upload without any session
/// at all.
pub fn session_id_from_cookie(headers: &HeaderMap) -> Option<String> {
    headers
        .get("cookie")?
        .to_str()
        .ok()?
        .split(';')
        .find_map(|pair| {
            let (name, value) = pair.split_once('=')?;
            let session_id: &str = value.trim();
            (name.trim() == "sid" && !session_id.is_empty() && !session_id.contains(','))
                .then(|| session_id.to_owned())
        })
}

fn uploader(state: &Mutex<AppState>, headers: &HeaderMap) -> Option<Uploader> {
    let is_backend: bool = match headers.get("x-secret-key").and_then(|v| v.to_str().ok()) {
        Some(provided) => provided
            .as_bytes()
            .to_vec()
            .ct_eq(&state.lock().unwrap().secret_key)
            .into(),
        None => false,
    };

    if is_backend {
        Some(Uploader::Backend)
    } else {
        session_id_from_cookie(headers).map(Uploader::Session)
    }
}

async fn upload_endpoint(
    State(state): State<Arc<Mutex<AppState>>>,
    request: Request,
) -> Response<String> {
    let uploader: Option<Uploader> = uploader(&state, request.headers());
    let secret_key: Vec<u8> = state.lock().unwrap().secret_key.clone();

    match (uploader, request.extract::<Bytes, _>().await) {
        (Some(uploader2), Ok(bytes)) => file_upload_helper(&secret_key, &uploader2, bytes).await,
        _ => response_with_headers(
            StatusCode::UNAUTHORIZED,
            String::from("Invalid permissions 1"),
        ),
    }
}

/// How big an encrypted thumbnail may be. The client makes these at most
/// `MAX_THUMBNAIL_HEIGHT * 3` by `MAX_THUMBNAIL_HEIGHT` and encodes them as webp,
/// which lands well under this. The limit is here to bound what a caller who
/// isn't our own client can write, since an encrypted thumbnail cannot be
/// decoded to check it is what it claims to be.
const MAX_ENCRYPTED_THUMBNAIL_BYTES: usize = 1024 * 1024;

/// Splits an encrypted upload into its thumbnail and its file.
///
/// The body is the thumbnail's length as a big endian `u32`, then that many bytes
/// of thumbnail, then the rest is the file. A length of zero means no thumbnail
/// was sent. Only the thumbnail needs a length: the file is whatever is left.
fn split_encrypted_upload(bytes: &Bytes) -> Option<(Bytes, Bytes)> {
    let length_bytes: [u8; 4] = bytes.get(0..4)?.try_into().ok()?;
    let thumbnail_length = usize::try_from(u32::from_be_bytes(length_bytes)).ok()?;
    let file_start: usize = 4usize.checked_add(thumbnail_length)?;

    if file_start > bytes.len() {
        return None;
    }

    Some((bytes.slice(4..file_start), bytes.slice(file_start..)))
}

/// An encrypted file, and optionally a thumbnail of it, in one request.
///
/// The server is handed ciphertext, so unlike `/file/upload` there is no metadata
/// it can read and no thumbnail it can make. The client makes the thumbnail
/// instead and sends it along here, where it is stored under the same hash as the
/// file so that nothing has to keep track of a second one.
async fn upload_encrypted_endpoint(
    State(state): State<Arc<Mutex<AppState>>>,
    request: Request,
) -> Response<String> {
    let uploader: Option<Uploader> = uploader(&state, request.headers());
    let secret_key: Vec<u8> = state.lock().unwrap().secret_key.clone();

    let (uploader2, bytes) = match (uploader, request.extract::<Bytes, _>().await) {
        (Some(uploader2), Ok(bytes)) => (uploader2, bytes),
        _ => {
            return response_with_headers(
                StatusCode::UNAUTHORIZED,
                String::from("Invalid permissions"),
            );
        }
    };

    let (thumbnail, file) = match split_encrypted_upload(&bytes) {
        Some(split) => split,
        None => {
            return response_with_headers(
                StatusCode::BAD_REQUEST,
                String::from("Expected a thumbnail length, a thumbnail, then a file"),
            );
        }
    };

    if thumbnail.len() > MAX_ENCRYPTED_THUMBNAIL_BYTES {
        return response_with_headers(
            StatusCode::PAYLOAD_TOO_LARGE,
            format!("A thumbnail can be at most {MAX_ENCRYPTED_THUMBNAIL_BYTES} bytes"),
        );
    }

    let hash = hash_bytes(&file);

    // The size the file is displayed at is in the message the file is attached
    // to, which is encrypted too, so there is nothing to report here.
    if is_file_upload_allowed(&secret_key, hash.clone(), file.len(), &uploader2, (0, 0))
        .await
        .is_err()
    {
        return response_with_headers(
            StatusCode::UNAUTHORIZED,
            String::from("Invalid permissions"),
        );
    }

    // Reached only once the caller is known to be allowed to upload, so that the
    // answer doesn't tell a stranger which files already have a thumbnail.
    store_encrypted_upload(&hash, &thumbnail, &file)
}

/// Writes an encrypted upload, refusing a thumbnail for a file that has one.
///
/// A thumbnail is written once and never replaced: it is stored under the file's
/// own hash, so overwriting one would change what everyone sees of a file that is
/// already stored.
fn store_encrypted_upload(hash: &str, thumbnail: &Bytes, file: &Bytes) -> Response<String> {
    let thumbnail_path = thumbnail_filepath(hash);

    if !thumbnail.is_empty() && fs::exists(&thumbnail_path).unwrap_or(false) {
        return response_with_headers(
            StatusCode::CONFLICT,
            String::from("That file already has a thumbnail"),
        );
    }

    let path = filepath(hash);

    if !fs::exists(&path).unwrap_or(false) && fs::write(&path, file).is_err() {
        return response_with_headers(
            StatusCode::INTERNAL_SERVER_ERROR,
            String::from("Internal error"),
        );
    }

    if !thumbnail.is_empty() && fs::write(&thumbnail_path, thumbnail).is_err() {
        return response_with_headers(
            StatusCode::INTERNAL_SERVER_ERROR,
            String::from("Internal error"),
        );
    }

    json_response_with_headers(
        StatusCode::OK,
        serde_json::to_string(&UploadResponse {
            image_metadata: None,
            video_metadata: None,
            hash: String::from(hash),
        })
        .unwrap(),
    )
}

/// Lives under `/file/internal/` because only the backend fetches attachments by
/// url, so `require_internal_secret` has already checked the caller by the time
/// this runs.
async fn upload_url_endpoint(
    State(state): State<Arc<Mutex<AppState>>>,
    Json(UploadUrl { url }): Json<UploadUrl>,
) -> Response<String> {
    let secret_key: Vec<u8> = state.lock().unwrap().secret_key.clone();

    match reqwest::Client::new().get(url).send().await {
        Ok(response) => match response.bytes().await {
            Ok(bytes) => file_upload_helper(&secret_key, &Uploader::Backend, bytes).await,
            Err(_) => response_with_headers(
                StatusCode::UNAUTHORIZED,
                String::from("Invalid permissions 2"),
            ),
        },
        Err(_) => response_with_headers(
            StatusCode::UNAUTHORIZED,
            String::from("Invalid permissions 1"),
        ),
    }
}

/// Should match RichText.maxImageHeight
const MAX_THUMBNAIL_HEIGHT: u32 = 600;

/// Where Lamdera answers RPC calls, which differs between the local `lamdera
/// live` and the deployed app.
pub fn rpc_url(endpoint: &str) -> String {
    if cfg!(debug_assertions) {
        format!("http://localhost:8000/_r/{endpoint}")
    } else {
        format!("https://at-chat.app/_r/{endpoint}")
    }
}

/// Asks Lamdera whether this upload is allowed.
///
/// The server secret goes along with the question so that Lamdera can tell our
/// answer apart from anyone else's: `_r/is-file-upload-allowed` is a public url,
/// and without it a stranger could register files that were never uploaded.
async fn is_file_upload_allowed(
    secret_key: &[u8],
    hash: String,
    size: usize,
    uploader: &Uploader,
    (width, height): (u32, u32),
) -> Result<(), ()> {
    // An empty session is how the backend says the upload was its own. It has
    // already proved that with the secret key, which Lamdera checks as well.
    let session_id: &str = match uploader {
        Uploader::Session(session_id2) => session_id2,
        Uploader::Backend => "",
    };

    match reqwest::Client::new()
        .post(rpc_url("is-file-upload-allowed"))
        .header("Content-Type", "text/plain")
        .header("x-secret-key", String::from_utf8_lossy(secret_key).as_ref())
        .body(format!("{hash},{size},{session_id},{width},{height}"))
        .send()
        .await
    {
        Ok(response) => match response.text().await {
            Ok(text) => {
                if text == "valid" {
                    Ok(())
                } else {
                    Err(())
                }
            }
            Err(_) => Err(()),
        },
        Err(_) => Err(()),
    }
}

#[derive(Debug, Serialize)]
pub struct ImageMetadata {
    pub image_size: (u32, u32),
    pub orientation: Option<u8>,
    pub gps_location: Option<Location>,
    pub camera_owner: Option<String>,
    pub exposure_time: Option<ExposureTime>,
    pub f_number: Option<f32>,
    pub focal_length: Option<f32>,
    pub iso_speed_rating: Option<u16>,
    pub make: Option<String>,
    pub model: Option<String>,
    pub software: Option<String>,
    pub user_comment: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct ExposureTime {
    numerator: u32,
    denominator: u32,
}

#[derive(Debug, Serialize)]
pub struct UploadResponse {
    image_metadata: Option<ImageMetadata>,
    video_metadata: Option<video::VideoMetadata>,
    hash: String,
}

fn default_image_metadata(width: u32, height: u32) -> ImageMetadata {
    ImageMetadata {
        image_size: (width, height),
        orientation: None,
        gps_location: None,
        camera_owner: None,
        exposure_time: None,
        f_number: None,
        focal_length: None,
        iso_speed_rating: None,
        make: None,
        model: None,
        software: None,
        user_comment: None,
    }
}

#[derive(Debug, Serialize)]
pub struct Location {
    pub lat: f64,
    pub lon: f64,
}

fn to_degrees((degrees, minutes, seconds): (f64, f64, f64)) -> f64 {
    degrees + minutes / 60.0 + seconds / (60.0 * 60.0)
}

fn image_metadata(
    width: u32,
    height: u32,
    format: image::ImageFormat,
    bytes: Vec<u8>,
) -> ImageMetadata {
    match format {
        image::ImageFormat::Jpeg => {
            match gufo_jpeg::Jpeg::new(bytes) {
                Ok(jpeg) => {
                    match jpeg.exif_data().next() {
                        Some(raw_exif) => match gufo_exif::Exif::new(raw_exif.to_vec()) {
                            Ok(exif) => {
                                let orientation: Option<gufo_common::orientation::Orientation> =
                                    exif.orientation();

                                let image_size: (u32, u32) = match orientation {
                                    Some(orientation2) => match orientation2 {
                                        gufo_common::orientation::Orientation::Rotation90 | gufo_common::orientation::Orientation::Rotation270 | gufo_common::orientation::Orientation::MirroredRotation90 | gufo_common::orientation::Orientation::MirroredRotation270 => (height, width),
                                        gufo_common::orientation::Orientation::Id | gufo_common::orientation::Orientation::Rotation180 | gufo_common::orientation::Orientation::Mirrored | gufo_common::orientation::Orientation::MirroredRotation180 => (width, height),
                                    },
                                    None => (width, height),
                                };

                                ImageMetadata {
                                    image_size,
                                    orientation: orientation.map(|a| a as u8),
                                    gps_location: exif.gps_location().map(|a| Location {
                                        lat: to_degrees(a.lat.as_deg_min_sec()),
                                        lon: to_degrees(a.lon.as_deg_min_sec()),
                                    }),
                                    camera_owner: exif.camera_owner(),
                                    exposure_time: exif.exposure_time().map(|(a, b)| {
                                        ExposureTime {
                                            numerator: a,
                                            denominator: b,
                                        }
                                    }),
                                    f_number: exif.f_number(),
                                    focal_length: exif.focal_length(),
                                    iso_speed_rating: exif.iso_speed_rating(),
                                    make: exif.make(),
                                    model: exif.model(),
                                    software: exif.software(),
                                    user_comment: exif.user_comment(),
                                }
                            }
                            Err(_) => default_image_metadata(width, height),
                        },
                        None => default_image_metadata(width, height),
                    }
                }
                Err(_) => default_image_metadata(width, height),
            }
        }
        _ => default_image_metadata(width, height),
    }
}

async fn file_upload_helper(
    secret_key: &[u8],
    uploader: &Uploader,
    bytes: Bytes,
) -> Response<String> {
    let hash = hash_bytes(&bytes);

    let size = bytes.len();

    let reader = ImageReader::new(std::io::Cursor::new(&bytes));

    match reader
        .with_guessed_format()
        .map(|a| (a.format(), a.decode()))
    {
        Ok((Some(format), Ok(image))) => {
            let (width, height) = image.dimensions();

            let metadata = image_metadata(width, height, format, bytes.to_vec());

            let orientation: Orientation = match metadata.orientation {
                Some(orientation2) => {
                    Orientation::from_exif(orientation2).unwrap_or(Orientation::NoTransforms)
                }
                None => Orientation::NoTransforms,
            };

            let image_size = metadata.image_size;

            match is_file_upload_allowed(secret_key, hash.clone(), size, uploader, image_size).await
            {
                Ok(()) => {
                    let path = filepath(&hash);
                    let response: String = serde_json::to_string(&UploadResponse {
                        image_metadata: Some(metadata),
                        video_metadata: None,
                        hash: hash.clone(),
                    })
                    .unwrap();

                    match fs::exists(&path) {
                        Ok(true) => json_response_with_headers(StatusCode::OK, response),
                        _ => match fs::write(path, bytes) {
                            Ok(()) => {
                                let (width2, height2) = image_size;
                                if height2 > MAX_THUMBNAIL_HEIGHT
                                    || width2 > MAX_THUMBNAIL_HEIGHT * 3
                                {
                                    let mut resized_image = image.resize(
                                        MAX_THUMBNAIL_HEIGHT * 3,
                                        MAX_THUMBNAIL_HEIGHT,
                                        image::imageops::FilterType::Triangle,
                                    );
                                    resized_image.apply_orientation(orientation);

                                    let _ = resized_image.save_with_format(
                                        thumbnail_filepath(&hash),
                                        image::ImageFormat::WebP,
                                    );
                                }

                                json_response_with_headers(StatusCode::OK, response)
                            }
                            Err(_) => response_with_headers(
                                StatusCode::INTERNAL_SERVER_ERROR,
                                String::from("Internal error"),
                            ),
                        },
                    }
                }

                Err(()) => response_with_headers(
                    StatusCode::UNAUTHORIZED,
                    String::from("Invalid permissions"),
                ),
            }
        }
        // Not something the image crate can read. It might still be a video, in
        // which case the container header has plenty to say about it.
        _ => {
            let metadata: Option<video::VideoMetadata> = video::video_metadata(&bytes);
            let video_size: (u32, u32) = match &metadata {
                Some(metadata2) => metadata2.video_size,
                None => (0, 0),
            };

            match is_file_upload_allowed(secret_key, hash.clone(), size, uploader, video_size).await
            {
                Ok(()) => {
                    let path = filepath(&hash);
                    let response: String = serde_json::to_string(&UploadResponse {
                        image_metadata: None,
                        video_metadata: metadata,
                        hash: hash.clone(),
                    })
                    .unwrap();

                    match fs::exists(&path) {
                        Ok(true) => json_response_with_headers(StatusCode::OK, response),

                        _ => match fs::write(path, bytes) {
                            Ok(()) => json_response_with_headers(StatusCode::OK, response),
                            Err(_) => response_with_headers(
                                StatusCode::INTERNAL_SERVER_ERROR,
                                String::from("Internal error"),
                            ),
                        },
                    }
                }

                Err(()) => response_with_headers(
                    StatusCode::UNAUTHORIZED,
                    String::from("Invalid permissions"),
                ),
            }
        }
    }
}

/// The page these endpoints are called from, and the only origin they answer
/// for. It cannot be `*` any more: browsers reject a wildcard on a request that
/// carries credentials, and uploads now rely on the `sid` cookie being sent.
const fn allowed_origin() -> &'static str {
    if cfg!(debug_assertions) {
        // Lamdera live serves the app from a different port to this server,
        // which makes every request cross-origin during development.
        "http://localhost:8000"
    } else {
        "https://at-chat.app"
    }
}

fn response_with_headers(status_code: StatusCode, body: impl Into<String>) -> Response<String> {
    Response::builder()
        .status(status_code)
        .header("Access-Control-Allow-Origin", allowed_origin())
        .header("Access-Control-Allow-Credentials", "true")
        .header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        .header("Access-Control-Allow-Headers", "content-type, x-secret-key")
        .header("Content-Type", "text/plain")
        .body(body.into())
        .unwrap()
}

fn json_response_with_headers(
    status_code: StatusCode,
    body: impl Into<String>,
) -> Response<String> {
    Response::builder()
        .status(status_code)
        .header("Access-Control-Allow-Origin", allowed_origin())
        .header("Access-Control-Allow-Credentials", "true")
        .header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        .header("Access-Control-Allow-Headers", "content-type, x-secret-key")
        .header("Content-Type", "application/json")
        .body(body.into())
        .unwrap()
}

fn hash_bytes(bytes: &Bytes) -> String {
    base64_encode(&Sha224::digest(bytes))
}

async fn get_file_thumbnail_endpoint(Path(hash): Path<String>) -> http::Response<Body> {
    let is_valid_hash: bool = hash
        .chars()
        .all(|x| x.is_ascii_alphanumeric() || x == '-' || x == '_');

    if is_valid_hash {
        match fs::read(thumbnail_filepath(&hash)) {
            Result::Ok(data) => Response::builder()
                .status(StatusCode::OK)
                .header("Content-Type", "image/webp")
                .header("Content-Disposition", "inline")
                .header("Cache-Control", IMMUTABLE_CACHE_CONTROL)
                .body(Body::from(data))
                .unwrap(),
            Result::Err(_) => Response::builder()
                .status(StatusCode::NOT_FOUND)
                .body(Body::from("File not found"))
                .unwrap(),
        }
    } else {
        Response::builder()
            .status(StatusCode::BAD_REQUEST)
            .body(Body::from(format!("{hash} is an invalid filename")))
            .unwrap()
    }
}

async fn discord_sticker_endpoint(sticker_path: Path<String>) -> http::Response<Body> {
    let sticker_path2 = sticker_path.to_string();
    if sticker_path2
        .chars()
        .all(|x| x.is_ascii_alphanumeric() || x == '.')
        && sticker_path2.len() < 50
    {
        match reqwest::get(format!("https://discord.com/stickers/{}", sticker_path2)).await {
            Ok(bytes) => Response::builder()
                .status(StatusCode::OK)
                .header("Cache-Control", IMMUTABLE_CACHE_CONTROL)
                .body(Body::from(bytes.bytes().await.unwrap()))
                .unwrap(),
            Err(_) => Response::builder()
                .status(StatusCode::BAD_REQUEST)
                .body(Body::from(format!("Sticker does not exist")))
                .unwrap(),
        }
    } else {
        Response::builder()
            .status(StatusCode::BAD_REQUEST)
            .body(Body::from(format!("Invalid sticker format")))
            .unwrap()
    }
}

/// Files are addressed by a hash of their contents, so the bytes behind a given
/// URL can never change and the browser is free to keep them indefinitely
/// without revalidating. Without this the browser has no expiry and no
/// validator to work with, so every avatar and guild icon is redownloaded on
/// each page load.
const IMMUTABLE_CACHE_CONTROL: &str = "public, max-age=31536000, immutable";

/// Uploads are served from the same origin as the app, so an html or svg file
/// among them would otherwise run script with everything at-chat.app has:
/// the `sid` cookie, local storage, and the app's own requests. `sandbox` drops
/// the response into an opaque origin with no allowances, so such a file can no
/// longer read any of that, run script, submit a form or navigate the tab.
///
/// Images, video and audio are unaffected. The directive only applies to a
/// response loaded as a document, which is what a click on a file link does; an
/// `<img>` or `<video>` in the chat ignores it.
///
/// Pdfs need an allowance and get their own value below. Whatever is added here,
/// never pair `allow-scripts` with `allow-same-origin`: either alone keeps the
/// origin opaque, but together they undo it and hand the file back the access
/// this is taking away.
const SANDBOX_CSP: &str = "sandbox";

/// Safari draws a pdf with a viewer that is itself an html document driven by
/// script, so a bare `sandbox` leaves it unable to show the file at all.
/// `allow-scripts` gives that viewer its script back without giving up what the
/// sandbox is for: the origin stays opaque while `allow-same-origin` is absent,
/// so script here still cannot reach the sid cookie or the app's storage.
const PDF_SANDBOX_CSP: &str = "sandbox allow-scripts";

/// Which of the two a file is served with.
///
/// The content type is whatever the url asked for rather than anything about the
/// stored file, so any upload can claim to be a pdf and be served with script
/// allowed. That costs nothing while the origin is opaque, and `nosniff` is what
/// stops those bytes being rendered as the html they might really be.
///
/// Matching the type by name rather than by its index in `CONTENT_TYPES` keeps
/// this pointing at pdfs when entries are added to that list.
fn sandbox_csp(content_type: &str) -> &'static str {
    if content_type == "application/pdf" {
        PDF_SANDBOX_CSP
    } else {
        SANDBOX_CSP
    }
}

/// The content type on these responses is the one the url asked for, and the
/// sandbox above is chosen from it. Letting the browser sniff a different type
/// out of the bytes would decide the file is something other than what that
/// choice was made for.
const NOSNIFF: &str = "nosniff";

async fn get_file_endpoint(
    Path((content_type_index, hash)): Path<(String, String)>,
) -> http::Response<Body> {
    let is_valid_hash: bool = hash
        .chars()
        .all(|x| x.is_ascii_alphanumeric() || x == '-' || x == '_');

    if is_valid_hash {
        match fs::read(filepath(&hash)) {
            Result::Ok(data) => {
                let content_type = match content_type_index.parse::<usize>() {
                    Ok(index) => content_types::CONTENT_TYPES.get(index),
                    Err(_) => None,
                };

                match content_type {
                    Some(content_type2) => Response::builder()
                        .status(StatusCode::OK)
                        .header("Content-Type", *content_type2)
                        .header("Content-Disposition", "inline")
                        .header("Cache-Control", IMMUTABLE_CACHE_CONTROL)
                        .header("Content-Security-Policy", sandbox_csp(content_type2))
                        .header("X-Content-Type-Options", NOSNIFF)
                        .body(Body::from(data))
                        .unwrap(),
                    // No content type to send, so the browser would otherwise
                    // sniff one out of the bytes and could land on html. This
                    // branch is only reached by a url with an index the app never
                    // generates, so refusing to guess costs nothing.
                    None => Response::builder()
                        .status(StatusCode::OK)
                        .header("Cache-Control", IMMUTABLE_CACHE_CONTROL)
                        .header("Content-Security-Policy", SANDBOX_CSP)
                        .header("X-Content-Type-Options", NOSNIFF)
                        .body(Body::from(data))
                        .unwrap(),
                }
            }
            Result::Err(_) => Response::builder()
                .status(StatusCode::NOT_FOUND)
                .body(Body::from("File not found"))
                .unwrap(),
        }
    } else {
        Response::builder()
            .status(StatusCode::BAD_REQUEST)
            .body(Body::from(format!("{hash} is an invalid filename")))
            .unwrap()
    }
}

async fn fallback(uri: Uri) -> (StatusCode, String) {
    (StatusCode::NOT_FOUND, format!("No route for {uri}"))
}

/// Generated with Claude 4 Sonnet. Intentionally doesn't include padding = characters. Is url and filename safe.
fn base64_encode(data: &[u8]) -> String {
    const CHARS: &[u8; 64] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

    let mut result = String::new();
    let mut i: usize = 0;

    while i + 2 < data.len() {
        let b1 = data[i] as u32;
        let b2 = data[i + 1] as u32;
        let b3 = data[i + 2] as u32;

        let combined = (b1 << 16) | (b2 << 8) | b3;

        result.push(CHARS[((combined >> 18) & 0x3f) as usize] as char);
        result.push(CHARS[((combined >> 12) & 0x3f) as usize] as char);
        result.push(CHARS[((combined >> 6) & 0x3f) as usize] as char);
        result.push(CHARS[(combined & 0x3f) as usize] as char);

        i += 3;
    }

    match data.len() - i {
        1 => {
            let b1 = data[i] as u32;
            let combined = b1 << 16;
            result.push(CHARS[((combined >> 18) & 0x3f) as usize] as char);
            result.push(CHARS[((combined >> 12) & 0x3f) as usize] as char);
            // result.push('=');
            // result.push('=');
        }
        2 => {
            let b1 = data[i] as u32;
            let b2 = data[i + 1] as u32;
            let combined = (b1 << 16) | (b2 << 8);
            result.push(CHARS[((combined >> 18) & 0x3f) as usize] as char);
            result.push(CHARS[((combined >> 12) & 0x3f) as usize] as char);
            result.push(CHARS[((combined >> 6) & 0x3f) as usize] as char);
            // result.push('=');
        }
        _ => {} // No remaining bytes
    }

    result
}

/// Declarative notification that can be used to populate the payload of a web push.
///
/// See <https://webkit.org/blog/16535/meet-declarative-web-push>
#[derive(Debug, Serialize)]
pub struct Notification<D> {
    pub title: String,
    pub navigate: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub body: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub lang: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub dir: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub tag: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub image: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub icon: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub badge: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub vibrate: Option<Vec<u32>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub timestamp: Option<u64>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub renotify: Option<bool>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub silent: Option<bool>,

    #[serde(skip_serializing_if = "Option::is_none", rename = "requireInteraction")]
    pub require_interaction: Option<bool>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub data: Option<D>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub actions: Option<Vec<NotificationAction>>,
}

#[derive(Debug, Serialize)]
pub struct NotificationAction {
    pub title: String,
    pub action: String,
    pub navigate: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub icon: Option<String>,
}

impl<D: Serialize> Notification<D> {
    pub fn new(
        title: String,
        navigate: String,
        body: Option<String>,
        icon: Option<String>,
        data: Option<D>,
    ) -> Self {
        Self {
            title,
            navigate,
            lang: None,
            dir: None,
            tag: None,
            body,
            icon,
            image: None,
            badge: None,
            vibrate: None,
            timestamp: None,
            renotify: None,
            silent: None,
            require_interaction: None,
            data,
            actions: None,
        }
    }

    pub fn to_payload(&self, is_declarative: bool, mutable: bool) -> serde_json::Result<Vec<u8>> {
        serde_json::to_vec(&DeclarativePushPayload::new(self, is_declarative, mutable))
    }
}

#[derive(Debug, Serialize)]
struct DeclarativePushPayload<'a, D> {
    web_push: u16,
    pub notification: &'a Notification<D>,
    pub mutable: bool,
}

impl<'a, D: Serialize> DeclarativePushPayload<'a, D> {
    pub fn new(notification: &'a Notification<D>, is_declarative: bool, mutable: bool) -> Self {
        DeclarativePushPayload {
            web_push: if is_declarative { 8030 } else { 0 },
            notification,
            mutable: mutable,
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PushNotification {
    pub endpoint: String,
    pub p256dh: String,
    pub auth: String,
    pub private_key: String,
    pub title: String,
    pub body: String,
    pub icon: String,
    pub navigate: String,
    pub data: Option<String>,
    pub mutable : bool,
    pub is_declarative: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct EmbedRequest {
    pub url: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct EmbedResponse {
    pub title: Option<String>,
    pub description: Option<String>,
    pub image: Option<ImageData>,
    pub created_at: Option<i64>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ImageData {
    pub url: String,
    pub width: u32,
    pub height: u32,
    pub format: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CustomRequest {
    pub method: String,
    pub url: String,
    pub headers: Vec<Header>,
    pub body: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Header {
    key: String,
    value: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UploadUrl {
    pub url: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    // Regression test for the production crash where pasting a link to a binary
    // image file made post_embed feed the raw image bytes to the HTML parser,
    // overflowing the stack and aborting the whole server. The endpoint must now
    // return a response instead of crashing. If the host happens to be
    // unreachable from the test environment the endpoint still returns gracefully,
    // so this can never produce a false failure.
    #[tokio::test]
    async fn post_embed_does_not_crash_on_image_url() {
        let url = "https://at-chat.app/file/1/3SFn-guIRPHsr-z_L9bsJA9CCnWnDzWSKETXPA".to_owned();
        let response = post_embed(Json(EmbedRequest { url })).await;
        assert_eq!(
            response.status(),
            StatusCode::OK,
            "post_embed should return a response instead of crashing on an image URL"
        );
    }

    // Deterministic (offline) version of the same failure mode: a deeply nested
    // document recurses far enough in the parser to overflow a normal thread
    // stack. The dedicated large-stack parsing thread must absorb this without
    // aborting the process.
    #[test]
    fn parse_html_safe_survives_deeply_nested_html() {
        let deep = "<div>".repeat(20_000);
        let result = parse_html_safe(deep, "https://example.com".to_owned());
        assert!(
            result.is_some(),
            "deeply nested HTML should parse without crashing the server"
        );
    }

    // ---- helpers for hermetic metadata tests ----

    // Encode a solid-colour PNG of the given size, for serving as test image data.
    fn make_png(width: u32, height: u32) -> Vec<u8> {
        let buffer =
            image::ImageBuffer::from_pixel(width, height, image::Rgba([200u8, 100, 50, 255]));
        let mut bytes: Vec<u8> = Vec::new();
        image::DynamicImage::ImageRgba8(buffer)
            .write_to(&mut std::io::Cursor::new(&mut bytes), ImageFormat::Png)
            .expect("failed to encode test png");
        bytes
    }

    // Spawn a throwaway HTTP server on a random local port. `make_routes` receives
    // the server's own base URL (handy for embedding absolute links in HTML) and
    // returns the (path, content-type, body) responses to serve. Returns the base
    // URL the server is listening on.
    async fn spawn_test_server<F>(make_routes: F) -> String
    where
        F: FnOnce(&str) -> Vec<(&'static str, &'static str, Vec<u8>)>,
    {
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0")
            .await
            .expect("failed to bind test server");
        let base = format!("http://{}", listener.local_addr().unwrap());

        let mut router = axum::Router::new();
        for (path, content_type, body) in make_routes(&base) {
            router = router.route(
                path,
                axum::routing::get(move || {
                    let body = body.clone();
                    async move { ([(axum::http::header::CONTENT_TYPE, content_type)], body) }
                }),
            );
        }

        tokio::spawn(async move {
            let _ = axum::serve(listener, router).await;
        });

        base
    }

    #[tokio::test]
    async fn extracts_opengraph_metadata_from_html() {
        let base = spawn_test_server(|_base| {
            let html = r#"<html><head>
                <meta property="og:title" content="Hello World">
                <meta property="og:description" content="A short summary">
                <meta property="article:published_time" content="2020-01-02T03:04:05Z">
                </head><body>hi</body></html>"#
                .as_bytes()
                .to_vec();
            vec![("/", "text/html; charset=utf-8", html)]
        })
        .await;

        let client = reqwest::Client::new();
        let embed = build_embed(&client, &format!("{base}/"))
            .await
            .expect("expected an embed response");

        assert_eq!(
            embed.title.as_deref(),
            Some("Hello World"),
            "og:title should be extracted"
        );
        assert_eq!(
            embed.description.as_deref(),
            Some("A short summary"),
            "og:description should be extracted"
        );
        assert_eq!(
            embed.created_at,
            Some(1_577_934_245),
            "article:published_time should be parsed to a unix timestamp"
        );
        assert!(
            embed.image.is_none(),
            "no og:image was provided, so there should be no image"
        );
    }

    #[tokio::test]
    async fn direct_image_url_returns_image_dimensions() {
        let png = make_png(7, 4);
        let base = spawn_test_server(move |_base| vec![("/pic.png", "image/png", png)]).await;

        let client = reqwest::Client::new();
        let embed = build_embed(&client, &format!("{base}/pic.png"))
            .await
            .expect("expected an embed response");

        let image = embed.image.expect("expected image metadata");
        assert_eq!(
            (image.width, image.height),
            (7, 4),
            "image dimensions should be read from the file"
        );
        assert_eq!(image.format.as_deref(), Some("Png"), "format should be Png");
        // A link straight to an image is not an HTML page, so there is no
        // title/description to extract.
        assert!(
            embed.title.is_none(),
            "a direct image link has no page title"
        );
        assert!(
            embed.description.is_none(),
            "a direct image link has no page description"
        );
    }

    #[tokio::test]
    async fn resolves_image_from_og_image_tag() {
        let png = make_png(3, 9);
        let base = spawn_test_server(move |base| {
            let html = format!(
                r#"<html><head>
                    <meta property="og:title" content="Has Image">
                    <meta property="og:image" content="{base}/og.png">
                    </head><body></body></html>"#
            )
            .into_bytes();
            vec![
                ("/", "text/html; charset=utf-8", html),
                ("/og.png", "image/png", png),
            ]
        })
        .await;

        let client = reqwest::Client::new();
        let embed = build_embed(&client, &format!("{base}/"))
            .await
            .expect("expected an embed response");

        assert_eq!(
            embed.title.as_deref(),
            Some("Has Image"),
            "og:title should be extracted"
        );
        let image = embed.image.expect("expected og:image to be resolved");
        assert_eq!(
            (image.width, image.height),
            (3, 9),
            "og:image dimensions should be read from the linked file"
        );
        assert_eq!(image.format.as_deref(), Some("Png"), "format should be Png");
    }

    #[tokio::test]
    async fn page_without_metadata_returns_empty_fields() {
        let base = spawn_test_server(|_base| {
            vec![(
                "/",
                "text/html; charset=utf-8",
                b"<html><head><title>Plain</title></head><body>nothing here</body></html>".to_vec(),
            )]
        })
        .await;

        let client = reqwest::Client::new();
        let embed = build_embed(&client, &format!("{base}/"))
            .await
            .expect("expected an embed response");

        assert!(embed.title.is_none(), "no og:title -> no title");
        assert!(
            embed.description.is_none(),
            "no og:description -> no description"
        );
        assert!(embed.image.is_none(), "no og:image -> no image");
        assert!(
            embed.created_at.is_none(),
            "no article:published_time -> no created_at"
        );
    }

    #[tokio::test]
    async fn oversized_html_is_rejected() {
        // Build an HTML document comfortably larger than the 1 MB cap.
        let mut html = String::from(r#"<meta property="og:title" content="Too Big">"#);
        html.push_str(&"<!-- padding -->".repeat(1024 * 1024 / 10));
        let base = spawn_test_server(move |_base| {
            vec![("/", "text/html; charset=utf-8", html.into_bytes())]
        })
        .await;

        let client = reqwest::Client::new();
        assert!(
            build_embed(&client, &format!("{base}/")).await.is_none(),
            "HTML larger than the size cap should be rejected rather than parsed"
        );
    }

    // --- who an upload is attributed to ---

    fn headers_from(pairs: &[(&str, &str)]) -> HeaderMap {
        let mut headers = HeaderMap::new();
        for (name, value) in pairs {
            headers.insert(
                axum::http::HeaderName::from_str(name).expect("bad header name"),
                value.parse().expect("bad header value"),
            );
        }
        headers
    }

    fn test_state(secret: &str) -> Mutex<AppState> {
        Mutex::new(AppState {
            secret_key: secret.as_bytes().to_vec(),
        })
    }

    #[test]
    fn reads_the_session_out_of_the_sid_cookie() {
        let headers = headers_from(&[("cookie", "other=1; sid=abc123; another=2")]);
        assert_eq!(
            session_id_from_cookie(&headers).as_deref(),
            Some("abc123"),
            "the sid cookie should be found among the others"
        );
    }

    #[test]
    fn ignores_cookies_that_merely_end_in_sid() {
        let headers = headers_from(&[("cookie", "notsid=abc123")]);
        assert_eq!(
            session_id_from_cookie(&headers),
            None,
            "only a cookie named exactly sid should count"
        );
    }

    // The session id is one comma separated field among several in the question
    // put to Lamdera, so a comma in it would let the caller write the fields on
    // either side and claim any size or image dimensions it liked.
    #[test]
    fn refuses_a_session_containing_a_comma() {
        let headers = headers_from(&[("cookie", "sid=abc,999,,1,1")]);
        assert_eq!(
            session_id_from_cookie(&headers),
            None,
            "a session id that could forge extra fields should be refused"
        );
    }

    // An empty session id is what tells Lamdera the upload was the backend's
    // own, so `sid=` must not be read as a session or anybody at all could
    // upload without one.
    #[test]
    fn refuses_an_empty_session() {
        for cookie in ["sid=", "sid=   ", "other=1; sid=; another=2"] {
            let headers = headers_from(&[("cookie", cookie)]);
            assert_eq!(
                session_id_from_cookie(&headers),
                None,
                "an empty sid cookie should not be read as a session"
            );
            assert!(
                uploader(&test_state("the-secret"), &headers).is_none(),
                "an empty sid cookie should not be allowed to upload as the backend"
            );
        }
    }

    #[test]
    fn a_browser_uploads_as_the_session_in_its_cookie() {
        let state = test_state("the-secret");
        let headers = headers_from(&[("cookie", "sid=abc123")]);
        match uploader(&state, &headers) {
            Some(Uploader::Session(session_id)) => assert_eq!(session_id, "abc123"),
            _ => panic!("a request carrying a sid cookie should upload as that session"),
        }
    }

    #[test]
    fn the_server_secret_uploads_as_the_backend() {
        let state = test_state("the-secret");
        let headers = headers_from(&[("x-secret-key", "the-secret")]);
        assert!(
            matches!(uploader(&state, &headers), Some(Uploader::Backend)),
            "the secret key is how the backend identifies itself"
        );
    }

    #[test]
    fn a_wrong_secret_does_not_upload_as_the_backend() {
        let state = test_state("the-secret");
        let headers = headers_from(&[("x-secret-key", "not-the-secret")]);
        assert!(
            uploader(&state, &headers).is_none(),
            "a wrong secret with no cookie should not be allowed to upload at all"
        );
    }

    #[test]
    fn an_unidentified_request_cannot_upload() {
        let state = test_state("the-secret");
        assert!(
            uploader(&state, &HeaderMap::new()).is_none(),
            "a request with neither a cookie nor the secret should be refused"
        );
    }

    // --- the origin check ---

    // Serve a route behind `require_allowed_origin` and report what it answers.
    async fn origin_check_status(origin: Option<&str>) -> StatusCode {
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0")
            .await
            .expect("failed to bind test server");
        let base = format!("http://{}", listener.local_addr().unwrap());

        let router = Router::new()
            .route("/file/upload", post(|| async { "uploaded" }))
            .layer(axum::middleware::from_fn(require_allowed_origin));

        tokio::spawn(async move {
            let _ = axum::serve(listener, router).await;
        });

        let mut request = reqwest::Client::new().post(format!("{base}/file/upload"));
        if let Some(origin2) = origin {
            request = request.header("Origin", origin2);
        }
        request.send().await.expect("request failed").status()
    }

    #[tokio::test]
    async fn accepts_requests_from_the_app() {
        assert_eq!(
            origin_check_status(Some(allowed_origin())).await,
            StatusCode::OK,
            "the app's own origin should be allowed through"
        );
    }

    // Without this a third party page could POST here and the browser would
    // attach the sid cookie on its behalf.
    #[tokio::test]
    async fn rejects_requests_from_other_sites() {
        assert_eq!(
            origin_check_status(Some("https://evil.example")).await,
            StatusCode::FORBIDDEN,
            "an upload from somebody else's page should be refused"
        );
    }

    // Our own backend calls these endpoints server to server, where there is no
    // origin and no cookie for anyone to have ridden on.
    #[tokio::test]
    async fn allows_requests_that_are_not_from_a_browser() {
        assert_eq!(
            origin_check_status(None).await,
            StatusCode::OK,
            "a request without an Origin header should be allowed through"
        );
    }

    // Where the file endpoints read from and the upload endpoints write to.
    fn create_storage_dir() {
        create_dir_if_missing(String::from("./var"));
        create_dir_if_missing(String::from("./var/lib"));
        create_dir_if_missing(String::from("./var/lib/atchat"));
        create_dir_if_missing(String::from("./var/lib/atchat/storage"));
    }

    // Put a file where the endpoint looks for it and ask for it back, so the
    // tests below can read the headers it came with. Each caller passes its own
    // hash, which is the filename, so the two never tread on each other.
    async fn get_stored_file(
        hash: &str,
        content_type_index: String,
        bytes: &[u8],
    ) -> http::Response<Body> {
        create_storage_dir();
        fs::write(filepath(hash), bytes).expect("failed to write the file to serve");

        let response = get_file_endpoint(Path((content_type_index, hash.to_string()))).await;

        let _ = fs::remove_file(filepath(hash));

        response
    }

    fn content_security_policy(response: &http::Response<Body>) -> Option<&str> {
        response
            .headers()
            .get("Content-Security-Policy")
            .and_then(|value| value.to_str().ok())
    }

    fn index_of_content_type(content_type: &str) -> usize {
        content_types::CONTENT_TYPES
            .iter()
            .position(|candidate| *candidate == content_type)
            .unwrap_or_else(|| panic!("the content type list should contain {content_type}"))
    }

    // The content type is whatever the url asked for, so any upload can be
    // fetched back as html from at-chat.app itself. Without the sandbox its
    // script would run with the sid cookie and the app's storage in reach.
    #[tokio::test]
    async fn a_file_served_as_html_is_sandboxed() {
        let html_index = content_types::CONTENT_TYPES
            .iter()
            .position(|content_type| content_type.starts_with("text/html"))
            .expect("the content type list should contain text/html");

        let response = get_stored_file(
            "sandboxedHtmlFile",
            html_index.to_string(),
            b"<script>alert(document.cookie)</script>",
        )
        .await;

        assert_eq!(
            content_security_policy(&response),
            Some("sandbox"),
            "a file served as html should be sandboxed out of the app's origin"
        );
    }

    // --- encrypted uploads ---

    fn encrypted_body(thumbnail: &[u8], file: &[u8]) -> Bytes {
        let mut body: Vec<u8> = Vec::new();
        body.extend_from_slice(&u32::try_from(thumbnail.len()).unwrap().to_be_bytes());
        body.extend_from_slice(thumbnail);
        body.extend_from_slice(file);
        Bytes::from(body)
    }

    fn split_parts(thumbnail: &[u8], file: &[u8]) -> Option<(Vec<u8>, Vec<u8>)> {
        split_encrypted_upload(&encrypted_body(thumbnail, file))
            .map(|(thumbnail2, file2)| (thumbnail2.to_vec(), file2.to_vec()))
    }

    #[test]
    fn an_upload_splits_back_into_the_thumbnail_and_the_file() {
        assert_eq!(
            split_parts(b"thumb", b"the file"),
            Some((b"thumb".to_vec(), b"the file".to_vec())),
            "the thumbnail is what its length says and the file is the rest"
        );
    }

    // A length of zero is how the client says it had no thumbnail to send, which
    // is every video and any image small enough not to need one.
    #[test]
    fn an_upload_with_no_thumbnail_is_all_file() {
        assert_eq!(
            split_parts(b"", b"the file"),
            Some((Vec::new(), b"the file".to_vec())),
            "a length of zero should leave the whole body as the file"
        );
    }

    #[test]
    fn a_body_too_short_to_hold_a_length_is_refused() {
        assert_eq!(
            split_encrypted_upload(&Bytes::from_static(b"abc")),
            None,
            "a body with no room for the length should not be read as an upload"
        );
    }

    // The length is the only thing saying where the thumbnail ends, so one that
    // runs past the body has to be refused rather than clamped.
    #[test]
    fn a_thumbnail_longer_than_the_body_is_refused() {
        let mut body: Vec<u8> = Vec::new();
        body.extend_from_slice(&100u32.to_be_bytes());
        body.extend_from_slice(b"only a few bytes");

        assert_eq!(
            split_encrypted_upload(&Bytes::from(body)),
            None,
            "a thumbnail that runs past the end of the body should be refused"
        );
    }

    #[test]
    fn a_thumbnail_length_that_cannot_be_a_size_is_refused() {
        let mut body: Vec<u8> = Vec::new();
        body.extend_from_slice(&u32::MAX.to_be_bytes());
        body.extend_from_slice(b"a file");

        assert_eq!(
            split_encrypted_upload(&Bytes::from(body)),
            None,
            "a length that cannot fit the body should be refused rather than wrap"
        );
    }

    // Storing writes to the same directory the file endpoints read from, so each
    // test picks its own hash and clears up after itself.
    fn store_encrypted(hash: &str, thumbnail: &[u8], file: &[u8]) -> Response<String> {
        create_storage_dir();

        store_encrypted_upload(
            hash,
            &Bytes::copy_from_slice(thumbnail),
            &Bytes::copy_from_slice(file),
        )
    }

    fn forget_stored(hash: &str) {
        let _ = fs::remove_file(filepath(hash));
        let _ = fs::remove_file(thumbnail_filepath(hash));
    }

    #[tokio::test]
    async fn an_encrypted_file_and_its_thumbnail_are_stored_under_the_same_hash() {
        let hash = "encryptedWithThumbnail";
        forget_stored(hash);

        let response = store_encrypted(hash, b"the thumbnail", b"the file");
        let stored_file = fs::read(filepath(hash));
        let stored_thumbnail = fs::read(thumbnail_filepath(hash));
        forget_stored(hash);

        assert_eq!(response.status(), StatusCode::OK);
        assert_eq!(
            stored_file.ok(),
            Some(b"the file".to_vec()),
            "the file should be stored under its hash"
        );
        assert_eq!(
            stored_thumbnail.ok(),
            Some(b"the thumbnail".to_vec()),
            "the thumbnail should be stored under the file's hash rather than one of its own"
        );
    }

    #[tokio::test]
    async fn an_encrypted_file_can_be_stored_without_a_thumbnail() {
        let hash = "encryptedWithoutThumbnail";
        forget_stored(hash);

        let response = store_encrypted(hash, b"", b"the file");
        let stored_thumbnail_exists = fs::exists(thumbnail_filepath(hash)).unwrap_or(false);
        forget_stored(hash);

        assert_eq!(response.status(), StatusCode::OK);
        assert!(
            !stored_thumbnail_exists,
            "sending no thumbnail should not leave an empty one behind"
        );
    }

    // The thumbnail is stored under the file's hash, so accepting a second one
    // would change what everyone sees of a file that is already there.
    #[tokio::test]
    async fn a_second_thumbnail_for_the_same_file_is_refused() {
        let hash = "encryptedThumbnailTwice";
        forget_stored(hash);

        let first = store_encrypted(hash, b"the thumbnail", b"the file");
        let second = store_encrypted(hash, b"a replacement", b"the file");
        let stored_thumbnail = fs::read(thumbnail_filepath(hash));
        forget_stored(hash);

        assert_eq!(first.status(), StatusCode::OK);
        assert_eq!(
            second.status(),
            StatusCode::CONFLICT,
            "a file that already has a thumbnail should not take another"
        );
        assert_eq!(
            stored_thumbnail.ok(),
            Some(b"the thumbnail".to_vec()),
            "the thumbnail that was already stored should be left alone"
        );
    }

    // Sending the file again without a thumbnail is not an attempt to replace
    // one, so there is nothing to refuse.
    #[tokio::test]
    async fn a_file_that_is_already_stored_can_be_sent_again() {
        let hash = "encryptedStoredTwice";
        forget_stored(hash);

        let first = store_encrypted(hash, b"", b"the file");
        let second = store_encrypted(hash, b"", b"the file");
        forget_stored(hash);

        assert_eq!(first.status(), StatusCode::OK);
        assert_eq!(second.status(), StatusCode::OK);
    }

    // Both of these are answered before the upload is authorised, so they can be
    // driven through the endpoint itself without an rpc to answer them.
    async fn upload_encrypted_status(body: Bytes) -> StatusCode {
        let request = Request::builder()
            .method("POST")
            .uri("/file/upload-encrypted")
            .header("cookie", "sid=abc123")
            .body(Body::from(body))
            .unwrap();

        upload_encrypted_endpoint(State(Arc::new(test_state("the-secret"))), request)
            .await
            .status()
    }

    #[tokio::test]
    async fn a_body_that_is_not_an_upload_is_refused() {
        assert_eq!(
            upload_encrypted_status(Bytes::from_static(b"ab")).await,
            StatusCode::BAD_REQUEST,
            "a body that isn't a length followed by a thumbnail and a file should be refused"
        );
    }

    // An encrypted thumbnail cannot be decoded to check it is one, so its size is
    // the only thing standing between the store and whatever a caller sends.
    #[tokio::test]
    async fn an_oversized_thumbnail_is_refused() {
        let thumbnail = vec![0u8; MAX_ENCRYPTED_THUMBNAIL_BYTES + 1];

        assert_eq!(
            upload_encrypted_status(encrypted_body(&thumbnail, b"the file")).await,
            StatusCode::PAYLOAD_TOO_LARGE,
            "a thumbnail past the limit should be refused"
        );
    }

    // Safari's pdf viewer is an html document that cannot draw anything without
    // script, so pdfs are served with script allowed. The origin stays opaque,
    // which is what keeps the app out of that script's reach.
    #[tokio::test]
    async fn a_pdf_is_allowed_the_script_its_viewer_is_built_from() {
        let response = get_stored_file(
            "sandboxedPdfFile",
            index_of_content_type("application/pdf").to_string(),
            b"%PDF-1.4",
        )
        .await;

        assert_eq!(
            content_security_policy(&response),
            Some("sandbox allow-scripts"),
            "a pdf should keep the sandbox but be allowed the script its viewer needs"
        );
    }

    // The one combination that would undo all of this: `allow-scripts` beside
    // `allow-same-origin` puts the file back on at-chat.app's own origin with
    // script in hand, which is the exploit these headers exist to close. No entry
    // in the list may be served that way, whatever else changes here.
    #[test]
    fn no_content_type_is_served_back_on_the_apps_origin() {
        for content_type in content_types::CONTENT_TYPES {
            let csp = sandbox_csp(content_type);

            assert!(
                csp == "sandbox" || csp.starts_with("sandbox "),
                "{content_type} is served with {csp}, which does not sandbox it"
            );
            assert!(
                !csp.contains("allow-same-origin"),
                "{content_type} is served with {csp}, which hands it back the app's origin"
            );
        }
    }

    // The sandbox is picked from the content type in the url, so a browser that
    // sniffed a different type out of the bytes would be rendering something
    // other than what that choice was made for.
    #[tokio::test]
    async fn a_served_file_is_not_sniffed() {
        let response = get_stored_file(
            "unsniffedFile",
            index_of_content_type("image/png").to_string(),
            b"not really a png",
        )
        .await;

        assert_eq!(
            response
                .headers()
                .get("X-Content-Type-Options")
                .and_then(|value| value.to_str().ok()),
            Some("nosniff"),
            "the browser should be told not to look for a type of its own"
        );
    }

    // This response carries no content type at all, so the browser picks one by
    // looking at the bytes and can arrive at html without being asked to.
    #[tokio::test]
    async fn a_file_with_no_content_type_to_send_is_sandboxed() {
        let response = get_stored_file(
            "sandboxedSniffedFile",
            (content_types::CONTENT_TYPES.len() + 1).to_string(),
            b"<script>alert(document.cookie)</script>",
        )
        .await;

        assert!(
            response.headers().get("Content-Type").is_none(),
            "an out of range index should be what leaves the content type unset"
        );
        assert_eq!(
            content_security_policy(&response),
            Some("sandbox"),
            "a file with no declared type should be sandboxed as well"
        );
        assert_eq!(
            response
                .headers()
                .get("X-Content-Type-Options")
                .and_then(|value| value.to_str().ok()),
            Some("nosniff"),
            "with no type declared, this is what stops the browser picking one"
        );
    }
}
