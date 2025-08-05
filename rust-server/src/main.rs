use axum::{
    Router,
    extract::Path,
    http::{StatusCode, Uri},
    routing::get,
    routing::post,
    body::{Bytes, Body},
};
use std::fs;
use sha2::{Sha256, Digest};

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/file/upload", post(upload_file_endpoint))
        .route("/file/{filename}", get(get_file_endpoint))
        .fallback(fallback);

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn upload_file_endpoint(body: Bytes) -> (StatusCode, Vec<u8>) {
    (StatusCode::BAD_REQUEST, b"Invalid filename".to_vec())
}

async fn get_file_endpoint(Path(path): Path<String>) -> (StatusCode, Vec<u8>) {
    let is_valid_filename = match path.split('.').collect::<Vec<_>>().as_slice() {
        [hash, filetype] => {
            hash.chars().all(|x| x.is_ascii_hexdigit())
                && filetype.chars().all(|x| x.is_alphabetic())
        }

        [hash] => hash.chars().all(|x| x.is_ascii_hexdigit()),

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
