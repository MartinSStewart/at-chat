use axum::RequestExt;
use axum::body::Body;
use axum::response::Response;
use axum::{
    Router,
    body::Bytes,
    extract::{DefaultBodyLimit, Path, Request},
    http::{StatusCode, Uri},
    routing::get,
    routing::post,
};
use sha2::{Digest, Sha256};
use std::fs;

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route(
            "/file/upload",
            post(upload_endpoint).options(options_endpoint),
        )
        .route("/file/{content_type}/{filename}", get(get_file_endpoint))
        .layer(DefaultBodyLimit::max(100 * 1024 * 1024))
        .fallback(fallback);

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn options_endpoint() -> Response<String> {
    response_with_headers(StatusCode::OK, String::from("OK"))
}

fn filepath(hash: String) -> String {
    String::from("./var/lib/atchat/") + &hash
}

async fn upload_endpoint(request: Request) -> Response<String> {
    println!("upload_file_endpoint {:#?}", request.method());

    let session_id: Option<String> = match request.headers().get("sid") {
        Some(header_value) => match header_value.to_str() {
            Ok(s) => Some(s.to_string()),
            Err(_) => None,
        },
        None => None,
    };

    match (session_id, request.extract::<Bytes, _>().await) {
        (Some(session_id2), Ok(bytes)) => {
            let hash: String = hash_bytes(&bytes);

            match reqwest::Client::new()
                .post("http://localhost:8000/_r/is-file-upload-allowed")
                .body(hash.clone() + "," + &session_id2)
                .send()
                .await
            {
                Ok(response) => match response.text().await {
                    Ok(text) => {
                        let path: String = filepath(hash.clone());
                        println!("{}", text);
                        if text == "valid" {
                            match fs::exists(&path) {
                                Ok(true) => response_with_headers(StatusCode::OK, hash),

                                _ => match fs::write(path, bytes) {
                                    Ok(()) => response_with_headers(StatusCode::OK, hash),
                                    Err(_) => response_with_headers(
                                        StatusCode::INTERNAL_SERVER_ERROR,
                                        String::from("Internal error"),
                                    ),
                                },
                            }
                        } else {
                            response_with_headers(
                                StatusCode::UNAUTHORIZED,
                                String::from("Invalid permissions"),
                            )
                        }
                    }

                    _ => response_with_headers(
                        StatusCode::UNAUTHORIZED,
                        String::from("Invalid permissions"),
                    ),
                },

                Err(_) => response_with_headers(
                    StatusCode::UNAUTHORIZED,
                    String::from("Invalid permissions"),
                ),
            }
        }
        _ => response_with_headers(
            StatusCode::UNAUTHORIZED,
            String::from("Invalid permissions"),
        ),
    }
}

fn response_with_headers(status_code: StatusCode, body: String) -> Response<String> {
    Response::builder()
        .status(status_code)
        .header("Access-Control-Allow-Origin", "*")
        .header("Access-Control-Allow-Headers", "*")
        .body(body)
        .unwrap()
}

fn hash_bytes(bytes: &Bytes) -> String {
    Sha256::digest(&bytes)
        .to_vec()
        .iter()
        .map(|b| format!("{:02x}", b))
        .collect()
}

async fn get_file_endpoint(
    Path((content_type, hash)): Path<(String, String)>,
) -> http::Response<Body> {
    println!("{}", hash);
    let is_valid_hash: bool = hash
        .chars()
        .all(|x| x.is_ascii_hexdigit() && !x.is_uppercase());

    if is_valid_hash {
        let data: Result<Vec<u8>, std::io::Error> = fs::read(filepath(hash));
        match data {
            Result::Ok(data) => {
                let content_type2: String = urlencoding::decode(&content_type)
                    .expect("UTF-8")
                    .to_string();
                Response::builder()
                    .status(StatusCode::OK)
                    .header("Content-Type", content_type2)
                    .body(Body::from(data))
                    .unwrap()
            }
            Result::Err(_) => Response::builder()
                .status(StatusCode::NOT_FOUND)
                .body(Body::from("File not found"))
                .unwrap(),
        }
    } else {
        Response::builder()
            .status(StatusCode::BAD_REQUEST)
            .body(Body::from("Invalid filename"))
            .unwrap()
    }
}

async fn fallback(uri: Uri) -> (StatusCode, String) {
    println!("Fallback endpoint");
    (StatusCode::NOT_FOUND, format!("No route for {uri}"))
}
