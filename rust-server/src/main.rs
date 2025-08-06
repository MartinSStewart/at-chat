use axum::RequestExt;
use axum::{
    Router,
    body::{Body, Bytes},
    extract::{Path, Request},
    http::{header::CONTENT_TYPE,StatusCode, Uri},
    routing::get,
    routing::post,
};
use sha2::{Digest, Sha256};
use std::fs;

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/file/upload", post(upload_file_endpoint))
        .route("/file/{filename}", get(get_file_endpoint))
        .fallback(fallback);

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn upload_file_endpoint(request: Request) -> (StatusCode, String) {
//     let content_type =
//         match request.headers().get(CONTENT_TYPE) {
//             Some(header) => {
//                 match header.to_str() {
//                     // https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/MIME_types/Common_types
//                     Ok("application/json") => Some("json"),
//                     Ok("application/pdf") => Some("pdf"),
//                     Ok("application/vnd.ms-powerpoint") => Some("ppt"),
//                     Ok("application/vnd.openxmlformats-officedocument.presentationml.presentation") => Some("pptx"),
//                     Ok("application/vnd.rar") => Some("rar"),
//                     Ok("application/x-tar") => Some("tar"),
//                     Ok("application/x-7z-compressed") => Some("7z"),
//                     Ok("application/xml") => Some("xml"),
//                     Ok("application/zip") => Some("zip"),
//                     Ok("audio/mpeg") => Some("mp3"),
//                     Ok("audio/ogg") => Some("oga"),
//                     Ok("audio/wav") => Some("wav"),
//                     Ok("audio/webm") => Some("weba"),
//                     Ok("image/apng") => Some("apng"),
//                     Ok("image/gif") => Some("gif"),
//                     Ok("image/jpeg") => Some("jpg"),
//                     Ok("image/png") => Some("png"),
//                     Ok("image/svg+xml") => Some("svg"),
//                     Ok("image/tiff") => Some("tif"),
//                     Ok("image/webp") => Some("webp"),
//                     Ok("text/css") => Some("css"),
//                     Ok("text/csv") => Some("csv"),
//                     Ok("text/html") => Some("html"),
//                     Ok("text/plain") => Some("txt"),
//                     Ok("text/xml") => Some("xml"),
//                     Ok("video/mp4") => Some("mp4"),
//                     Ok("video/mpeg") => Some("mpeg"),
//                     Ok("video/webm") => Some("webm"),
//                     Ok(_) => Some(""),
//                     Err(_) => None,
//                 }
//             },
//             None => None,
//         };

    match request.extract::<Bytes, _>().await {
        Ok(bytes) => {
            let hash: String = Sha256::digest(bytes)
                .to_vec()
                .iter()
                .map(|b| format!("{:02x}", b))
                .collect();
            (StatusCode::OK, hash)
        }
        Err(_) => (
            StatusCode::BAD_REQUEST,
            String::from("Failed to hash body of request"),
        ),
    }
}

async fn get_file_endpoint(Path(path): Path<String>) -> (StatusCode, Vec<u8>) {
    let is_valid_filename = match path.split('.').collect::<Vec<_>>().as_slice() {
        [hash, filetype] => {
            hash.chars()
                .all(|x| x.is_ascii_hexdigit() && x.is_lowercase())
                && filetype
                    .chars()
                    .all(|x| x.is_alphabetic() && x.is_lowercase())
        }

        [hash] => hash
            .chars()
            .all(|x| x.is_ascii_hexdigit() && x.is_lowercase()),

        _ => false,
    };

    if is_valid_filename {
        let data: Result<Vec<u8>, std::io::Error> =
            fs::read(String::from("./var/lib/atchat/") + &path);
        match data {
            Result::Ok(data) => (StatusCode::OK, data),
            Result::Err(_) => (StatusCode::NOT_FOUND, b"File not Found".to_vec()),
        }
    } else {
        (StatusCode::BAD_REQUEST, b"Invalid filename".to_vec())
    }
}

async fn fallback(uri: Uri) -> (StatusCode, String) {
    (StatusCode::NOT_FOUND, format!("No route for {uri}"))
}
