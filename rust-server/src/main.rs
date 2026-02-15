use axum::body::Body;
use axum::response::Response;
use axum::{Json, RequestExt};
use axum::{
    Router,
    body::Bytes,
    extract::{DefaultBodyLimit, Path, Request},
    http::{StatusCode, Uri},
    routing::get,
    routing::post,
};

use http::HeaderMap;
use image::metadata::Orientation;
use image::{self, GenericImageView, ImageReader};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha224};
use std::fs;
use std::str::FromStr;
use web_push::SubscriptionInfo;
mod content_types;

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route(
            "/file/upload",
            post(upload_endpoint).options(options_endpoint),
        )
        .route(
            "/file/push-notification",
            post(push_notification_endpoint).options(options_endpoint),
        )
        .route(
            "/file/custom-request",
            post(custom_request_endpoint).options(options_endpoint),
        )
        .route("/file/vapid", get(vapid_endpoint))
        .route("/file/{content_type}/{filename}", get(get_file_endpoint))
        .route("/file/t/{filename}", get(get_file_thumbnail_endpoint))
        .layer(DefaultBodyLimit::max(100 * 1024 * 1024))
        .fallback(fallback);

    match tokio::net::TcpListener::bind("0.0.0.0:3000").await {
        Ok(listener) => {
            let _ = axum::serve(listener, app).await;
        }
        Err(error) => {
            println!("Server didn't start:{error}");
        }
    };
}

async fn options_endpoint() -> Response<String> {
    response_with_headers(StatusCode::OK, String::from("OK"))
}

fn filepath(hash: &str) -> String {
    format!("./var/lib/atchat/{hash}")
}

fn thumbnail_filepath(hash: &str) -> String {
    format!("./var/lib/atchat/{hash}_thumbnail")
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

    let content = match content.to_payload() {
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
                web_push::WebPushError::Unauthorized(_) => String::from("Error 7"),
                web_push::WebPushError::BadRequest(error_info) => {
                    format!(
                        "Bad request. Error: {:?} Message: {:?}",
                        &error_info.error, &error_info.message
                    )
                }
                web_push::WebPushError::ServerError {
                    retry_after: _,
                    info: _,
                } => String::from("Error 8"),
                web_push::WebPushError::NotImplemented(_) => String::from("Error 9"),
                web_push::WebPushError::InvalidUri => String::from("Error 10"),
                web_push::WebPushError::EndpointNotValid(_) => String::from("Error 11"),
                web_push::WebPushError::EndpointNotFound(_) => String::from("Error 12"),
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

async fn upload_endpoint(request: Request) -> Response<String> {
    let session_id: Option<String> = match request.headers().get("sid") {
        Some(header_value) => match header_value.to_str() {
            Ok(s) => Some(s.to_owned()),
            Err(_) => None,
        },
        None => None,
    };

    match (session_id, request.extract::<Bytes, _>().await) {
        (Some(session_id2), Ok(bytes)) => file_upload_helper(session_id2, bytes).await,
        _ => response_with_headers(
            StatusCode::UNAUTHORIZED,
            String::from("Invalid permissions 1"),
        ),
    }
}

/// Should match RichText.maxImageHeight
const MAX_THUMBNAIL_HEIGHT: u32 = 600;

async fn is_file_upload_allowed(
    hash: String,
    size: usize,
    session_id: String,
    (width, height): (u32, u32),
) -> Result<(), ()> {
    match reqwest::Client::new()
        .post(if cfg!(debug_assertions) {
            "http://localhost:8000/_r/is-file-upload-allowed"
        } else {
            "https://at-chat.app/_r/is-file-upload-allowed"
        })
        .header("Content-Type", "text/plain")
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

async fn file_upload_helper(session_id2: String, bytes: Bytes) -> Response<String> {
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

            match is_file_upload_allowed(hash.clone(), size, session_id2, image_size).await {
                Ok(()) => {
                    let path = filepath(&hash);
                    let response: String = serde_json::to_string(&UploadResponse {
                        image_metadata: Some(metadata),
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
        _ => match is_file_upload_allowed(hash.clone(), size, session_id2, (0, 0)).await {
            Ok(()) => {
                let path = filepath(&hash);
                let response: String = serde_json::to_string(&UploadResponse {
                    image_metadata: None,
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
        },
    }
}

fn response_with_headers(status_code: StatusCode, body: impl Into<String>) -> Response<String> {
    Response::builder()
        .status(status_code)
        .header("Access-Control-Allow-Origin", "*")
        .header("Access-Control-Allow-Headers", "*")
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
        .header("Access-Control-Allow-Origin", "*")
        .header("Access-Control-Allow-Headers", "*")
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
                        .body(Body::from(data))
                        .unwrap(),
                    None => Response::builder()
                        .status(StatusCode::OK)
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

    pub fn to_payload(&self) -> serde_json::Result<Vec<u8>> {
        serde_json::to_vec(&DeclarativePushPayload::new(self))
    }
}

#[derive(Debug, Serialize)]
struct DeclarativePushPayload<'a, D> {
    web_push: u16,
    pub notification: &'a Notification<D>,
    pub mutable: bool,
}

impl<'a, D: Serialize> DeclarativePushPayload<'a, D> {
    pub fn new(notification: &'a Notification<D>) -> Self {
        DeclarativePushPayload {
            web_push: 8030,
            notification,
            mutable: true,
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
