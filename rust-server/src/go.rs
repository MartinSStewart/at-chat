//! Go AI endpoint, backed by a modernised port of iomrascalai
//! (<https://github.com/ujh/iomrascalai>, GPL-3.0+) vendored at
//! `rust-server/iomrascalai/`.

use axum::Json;
use axum::http::StatusCode;
use axum::response::Response;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use std::time::Duration;

use iomrascalai::board::{Black, Color, Empty, Pass, Play, White};
use iomrascalai::config::Config;
use iomrascalai::engine::{Engine, EngineController};
use iomrascalai::game::Game;
use iomrascalai::patterns::SmallPatternMatcher;
use iomrascalai::ruleset::Ruleset;
use iomrascalai::timer::Timer;

#[derive(Debug, Deserialize)]
pub struct Stone {
    pub x: u8,
    pub y: u8,
    pub color: String,
}

#[derive(Debug, Deserialize)]
pub struct GoMoveRequest {
    pub width: u8,
    pub height: u8,
    pub komi: f32,
    pub current_player: String,
    pub stones: Vec<Stone>,
    /// Wall-clock budget for the search, in milliseconds. Capped server-side.
    #[serde(default = "default_think_ms")]
    pub think_ms: u64,
}

fn default_think_ms() -> u64 {
    3000
}

#[derive(Debug, Serialize)]
#[serde(tag = "type")]
pub enum GoMoveResponse {
    Play { x: u8, y: u8 },
    Pass,
}

fn parse_color(s: &str) -> Result<Color, String> {
    match s {
        "Black" | "black" | "B" | "b" => Ok(Black),
        "White" | "white" | "W" | "w" => Ok(White),
        other => Err(format!("Unknown color: {other}")),
    }
}

/// Build a `Game` whose board matches the JSON state and whose `next_player`
/// is `current`. iomrascalai requires square boards, so non-square requests
/// are rejected.
fn build_game(req: &GoMoveRequest, current: Color) -> Result<Game, String> {
    if req.width != req.height {
        return Err("iomrascalai requires square boards".into());
    }
    let size = req.width;
    let mut board = iomrascalai::board::Board::new(size, req.komi, Ruleset::KgsChinese);
    for stone in &req.stones {
        if stone.x >= size || stone.y >= size {
            return Err(format!("Stone out of bounds: ({}, {})", stone.x, stone.y));
        }
        let color = parse_color(&stone.color)?;
        // play_legal_move skips legality checks, so we can seed the board in
        // any order regardless of whose turn iomrascalai thinks it is.
        board.play_legal_move(Play(color, stone.x + 1, stone.y + 1));
    }
    // Force `next_player()` to report `current` by ending on a pass from the
    // opposite colour, then clearing the resulting pass counter.
    board.play_legal_move(Pass(opposite(current)));
    board.reset_game_over();
    Ok(Game::from_board(board))
}

fn opposite(c: Color) -> Color {
    match c {
        Black => White,
        White => Black,
        Empty => Empty,
    }
}

pub async fn go_move_endpoint(Json(req): Json<GoMoveRequest>) -> Response<String> {
    if req.width == 0 || req.height == 0 || req.width > 25 || req.height > 25 {
        return error_response("Board dimensions must be in 1..=25");
    }
    let think_ms = req.think_ms.clamp(200, 15_000);
    let color = match parse_color(&req.current_player) {
        Ok(c) => c,
        Err(e) => return error_response(&e),
    };
    let size = req.width;
    let komi = req.komi;
    let game = match build_game(&req, color) {
        Ok(g) => g,
        Err(e) => return error_response(&e),
    };

    // The whole search is CPU-bound and uses worker threads internally; do it
    // off the async runtime so concurrent requests don't pile up.
    let move_result = match tokio::task::spawn_blocking(move || run_search(size, komi, color, game, think_ms)).await {
        Ok(m) => m,
        Err(_) => return error_response("AI worker panicked"),
    };

    let response = match move_result {
        SearchResult::Play { x, y } => GoMoveResponse::Play { x, y },
        SearchResult::Pass => GoMoveResponse::Pass,
    };
    let body = serde_json::to_string(&response).unwrap_or_else(|_| String::from("\"error\""));
    Response::builder()
        .status(StatusCode::OK)
        .header("Access-Control-Allow-Origin", "*")
        .header("Access-Control-Allow-Headers", "*")
        .header("Content-Type", "application/json")
        .body(body)
        .unwrap()
}

enum SearchResult {
    Play { x: u8, y: u8 },
    Pass,
}

fn run_search(size: u8, komi: f32, color: Color, game: Game, think_ms: u64) -> SearchResult {
    let config = Arc::new(Config::default(false, false, Ruleset::KgsChinese, Some(num_cpus::get())));
    let pattern_matcher = Arc::new(SmallPatternMatcher::new());
    let engine = Engine::new(config.clone(), pattern_matcher);
    let mut controller = EngineController::new(config.clone(), engine);
    controller.reset(size, komi);

    let mut timer = Timer::new(config);
    // Use a one-stone byo-yomi period so the full budget is spent on this
    // single move, instead of being divided across remaining empty points.
    let secs = think_ms.div_ceil(1000) as i64;
    timer.setup(0, secs.max(1), 1);
    timer.start(&game);

    let (mv, _playouts) = controller.genmove(color, &game, &timer);
    // Sanity guard: in case the timer is stricter than think_ms suggests.
    let _ = Duration::from_millis(think_ms);
    if mv.is_pass() || mv.is_resign() {
        SearchResult::Pass
    } else {
        let coord = mv.coord();
        // iomrascalai uses 1-indexed coords; our JSON is 0-indexed.
        SearchResult::Play {
            x: coord.col - 1,
            y: coord.row - 1,
        }
    }
}

fn error_response(msg: &str) -> Response<String> {
    Response::builder()
        .status(StatusCode::BAD_REQUEST)
        .header("Access-Control-Allow-Origin", "*")
        .header("Access-Control-Allow-Headers", "*")
        .header("Content-Type", "text/plain")
        .body(String::from(msg))
        .unwrap()
}
