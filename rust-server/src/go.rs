//! Go AI endpoint and engine.
//!
//! Heavily inspired by iomrascalai (<https://github.com/ujh/iomrascalai>), which
//! is GPL-3.0+. Vendored source under `vendored/ujh/iomrascalai/`. The board
//! representation, chain-based capture logic and Monte Carlo playout approach
//! are ported from there; this implementation is a smaller, self-contained
//! rewrite that avoids the original crate's nightly-only features and stale
//! dependencies.

use axum::Json;
use axum::http::StatusCode;
use axum::response::Response;
use rand::Rng;
use rand::seq::IndexedRandom;
use serde::{Deserialize, Serialize};
use std::collections::HashSet;

#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
enum Color {
    Black,
    White,
}

impl Color {
    fn opposite(self) -> Self {
        match self {
            Self::Black => Self::White,
            Self::White => Self::Black,
        }
    }
}

#[derive(Clone)]
struct Board {
    width: usize,
    height: usize,
    cells: Vec<Option<Color>>,
}

impl Board {
    fn new(width: usize, height: usize) -> Self {
        Self {
            width,
            height,
            cells: vec![None; width * height],
        }
    }

    fn idx(&self, x: usize, y: usize) -> usize {
        y * self.width + x
    }

    fn get(&self, x: usize, y: usize) -> Option<Color> {
        self.cells[self.idx(x, y)]
    }

    fn set(&mut self, x: usize, y: usize, c: Option<Color>) {
        let i = self.idx(x, y);
        self.cells[i] = c;
    }

    fn neighbors(&self, x: usize, y: usize) -> Vec<(usize, usize)> {
        let mut out = Vec::with_capacity(4);
        if x > 0 {
            out.push((x - 1, y));
        }
        if x + 1 < self.width {
            out.push((x + 1, y));
        }
        if y > 0 {
            out.push((x, y - 1));
        }
        if y + 1 < self.height {
            out.push((x, y + 1));
        }
        out
    }

    /// Flood-fill the chain of stones connected to (x, y), and return its
    /// stones plus its set of liberties.
    fn chain(&self, x: usize, y: usize) -> (HashSet<(usize, usize)>, HashSet<(usize, usize)>) {
        let mut stones: HashSet<(usize, usize)> = HashSet::new();
        let mut liberties: HashSet<(usize, usize)> = HashSet::new();
        let color = match self.get(x, y) {
            Some(c) => c,
            None => return (stones, liberties),
        };
        let mut queue = vec![(x, y)];
        stones.insert((x, y));
        while let Some((cx, cy)) = queue.pop() {
            for (nx, ny) in self.neighbors(cx, cy) {
                match self.get(nx, ny) {
                    None => {
                        liberties.insert((nx, ny));
                    }
                    Some(c) if c == color && !stones.contains(&(nx, ny)) => {
                        stones.insert((nx, ny));
                        queue.push((nx, ny));
                    }
                    _ => {}
                }
            }
        }
        (stones, liberties)
    }

    /// Returns the new board after playing `color` at (x, y), and the number
    /// of opposing stones captured. Returns None if the move is illegal
    /// (occupied, suicide, or simple ko vs `previous`).
    fn try_play(
        &self,
        x: usize,
        y: usize,
        color: Color,
        previous: Option<&Board>,
    ) -> Option<(Board, usize)> {
        if self.get(x, y).is_some() {
            return None;
        }
        let mut next = self.clone();
        next.set(x, y, Some(color));
        let opp = color.opposite();
        let mut captured = 0usize;
        for (nx, ny) in self.neighbors(x, y) {
            if next.get(nx, ny) == Some(opp) {
                let (stones, libs) = next.chain(nx, ny);
                if libs.is_empty() {
                    for (sx, sy) in &stones {
                        next.set(*sx, *sy, None);
                    }
                    captured += stones.len();
                }
            }
        }
        let (_, my_libs) = next.chain(x, y);
        if my_libs.is_empty() {
            return None;
        }
        if let Some(prev) = previous {
            if next.cells == prev.cells {
                return None;
            }
        }
        Some((next, captured))
    }

    /// True if (x, y) is empty and surrounded entirely by stones of `color`
    /// (and the diagonal neighbors are mostly the same color too). This is a
    /// simple eye heuristic: the playout policy avoids filling its own eyes.
    fn is_eye(&self, x: usize, y: usize, color: Color) -> bool {
        if self.get(x, y).is_some() {
            return false;
        }
        for (nx, ny) in self.neighbors(x, y) {
            if self.get(nx, ny) != Some(color) {
                return false;
            }
        }
        let mut diag_total = 0;
        let mut diag_friendly = 0;
        for (dx, dy) in [(-1i32, -1i32), (-1, 1), (1, -1), (1, 1)] {
            let nx = x as i32 + dx;
            let ny = y as i32 + dy;
            if nx < 0 || ny < 0 || nx >= self.width as i32 || ny >= self.height as i32 {
                // Off-board diagonals count toward the "hostile" budget,
                // matching the standard pseudo-eye rule.
                diag_total += 1;
                continue;
            }
            diag_total += 1;
            if self.get(nx as usize, ny as usize) == Some(color) {
                diag_friendly += 1;
            }
        }
        // On the edge / corner, all diagonals must be friendly. In the centre,
        // at most one may be hostile.
        let on_edge = x == 0 || y == 0 || x + 1 == self.width || y + 1 == self.height;
        if on_edge {
            diag_friendly == diag_total
        } else {
            diag_friendly + 1 >= diag_total
        }
    }

    /// Chinese-style area scoring: stones + territory. Ignores life/death;
    /// playouts run to the bitter end so dead stones get captured naturally.
    fn area_score(&self, komi: f32) -> f32 {
        let mut black = 0i32;
        let mut white = 0i32;
        let mut visited: HashSet<(usize, usize)> = HashSet::new();
        for y in 0..self.height {
            for x in 0..self.width {
                match self.get(x, y) {
                    Some(Color::Black) => black += 1,
                    Some(Color::White) => white += 1,
                    None => {
                        if visited.contains(&(x, y)) {
                            continue;
                        }
                        let mut region: Vec<(usize, usize)> = vec![(x, y)];
                        let mut q = vec![(x, y)];
                        visited.insert((x, y));
                        let mut touches_black = false;
                        let mut touches_white = false;
                        while let Some((cx, cy)) = q.pop() {
                            for (nx, ny) in self.neighbors(cx, cy) {
                                match self.get(nx, ny) {
                                    Some(Color::Black) => touches_black = true,
                                    Some(Color::White) => touches_white = true,
                                    None => {
                                        if visited.insert((nx, ny)) {
                                            region.push((nx, ny));
                                            q.push((nx, ny));
                                        }
                                    }
                                }
                            }
                        }
                        let size = region.len() as i32;
                        match (touches_black, touches_white) {
                            (true, false) => black += size,
                            (false, true) => white += size,
                            _ => {}
                        }
                    }
                }
            }
        }
        black as f32 - white as f32 - komi
    }
}

#[derive(Clone, Copy)]
enum PlayoutMove {
    Play(usize, usize),
    Pass,
}

fn legal_moves(board: &Board, color: Color, previous: Option<&Board>) -> Vec<(usize, usize)> {
    let mut moves = Vec::new();
    for y in 0..board.height {
        for x in 0..board.width {
            if board.get(x, y).is_some() {
                continue;
            }
            if board.is_eye(x, y, color) {
                continue;
            }
            if board.try_play(x, y, color, previous).is_some() {
                moves.push((x, y));
            }
        }
    }
    moves
}

fn random_playout<R: Rng>(
    rng: &mut R,
    start: &Board,
    start_player: Color,
    komi: f32,
    max_moves: usize,
) -> f32 {
    let mut board = start.clone();
    let mut previous: Option<Board> = None;
    let mut current = start_player;
    let mut consecutive_passes = 0u8;
    for _ in 0..max_moves {
        let moves = legal_moves(&board, current, previous.as_ref());
        let chosen = if let Some((mx, my)) = moves.choose(rng) {
            PlayoutMove::Play(*mx, *my)
        } else {
            PlayoutMove::Pass
        };
        match chosen {
            PlayoutMove::Play(mx, my) => match board.try_play(mx, my, current, previous.as_ref()) {
                Some((next, _)) => {
                    previous = Some(board);
                    board = next;
                    consecutive_passes = 0;
                }
                None => {
                    consecutive_passes += 1;
                    if consecutive_passes >= 2 {
                        break;
                    }
                }
            },
            PlayoutMove::Pass => {
                previous = Some(board.clone());
                consecutive_passes += 1;
                if consecutive_passes >= 2 {
                    break;
                }
            }
        }
        current = current.opposite();
    }
    board.area_score(komi)
}

fn pick_move(
    board: &Board,
    color: Color,
    previous: Option<&Board>,
    komi: f32,
    playouts_per_move: usize,
) -> Option<(usize, usize)> {
    let candidates = legal_moves(board, color, previous);
    if candidates.is_empty() {
        return None;
    }
    let mut rng = rand::rng();
    // Cap the playout length so a 19x19 game can't run forever.
    let max_moves = board.width * board.height * 3;
    let sign: f32 = match color {
        Color::Black => 1.0,
        Color::White => -1.0,
    };
    let mut best: Option<((usize, usize), f32)> = None;
    for (mx, my) in candidates {
        let (after, _) = match board.try_play(mx, my, color, previous) {
            Some(r) => r,
            None => continue,
        };
        let mut total: f32 = 0.0;
        for _ in 0..playouts_per_move {
            let s = random_playout(&mut rng, &after, color.opposite(), komi, max_moves);
            // Score is from Black's perspective; flip if we're White.
            total += sign * s;
        }
        let avg = total / playouts_per_move as f32;
        match best {
            None => best = Some(((mx, my), avg)),
            Some((_, b)) if avg > b => best = Some(((mx, my), avg)),
            _ => {}
        }
    }
    // If even the best move is worse than passing (negative for us), pass.
    let pass_score = {
        let mut total = 0.0;
        for _ in 0..playouts_per_move {
            total += sign * random_playout(&mut rand::rng(), board, color.opposite(), komi, max_moves);
        }
        total / playouts_per_move as f32
    };
    match best {
        Some((mv, score)) if score >= pass_score => Some(mv),
        _ => None,
    }
}

#[derive(Debug, Deserialize)]
pub struct Stone {
    pub x: usize,
    pub y: usize,
    pub color: String,
}

#[derive(Debug, Deserialize)]
pub struct GoMoveRequest {
    pub width: usize,
    pub height: usize,
    pub komi: f32,
    pub current_player: String,
    pub stones: Vec<Stone>,
    /// Optional previous board state (the most recent prior position) used for
    /// simple ko detection.
    #[serde(default)]
    pub previous_stones: Option<Vec<Stone>>,
    /// Number of random rollouts per candidate move.
    #[serde(default = "default_playouts")]
    pub playouts_per_move: usize,
}

fn default_playouts() -> usize {
    50
}

#[derive(Debug, Serialize)]
#[serde(tag = "type")]
pub enum GoMoveResponse {
    Play { x: usize, y: usize },
    Pass,
}

fn parse_color(s: &str) -> Result<Color, String> {
    match s {
        "Black" | "black" | "B" | "b" => Ok(Color::Black),
        "White" | "white" | "W" | "w" => Ok(Color::White),
        other => Err(format!("Unknown color: {other}")),
    }
}

fn build_board(width: usize, height: usize, stones: &[Stone]) -> Result<Board, String> {
    let mut board = Board::new(width, height);
    for s in stones {
        if s.x >= width || s.y >= height {
            return Err(format!("Stone out of bounds: ({}, {})", s.x, s.y));
        }
        board.set(s.x, s.y, Some(parse_color(&s.color)?));
    }
    Ok(board)
}

pub async fn go_move_endpoint(Json(req): Json<GoMoveRequest>) -> Response<String> {
    if req.width == 0 || req.height == 0 || req.width > 25 || req.height > 25 {
        return error_response("Board dimensions must be in 1..=25");
    }
    let playouts = req.playouts_per_move.clamp(1, 500);
    let board = match build_board(req.width, req.height, &req.stones) {
        Ok(b) => b,
        Err(e) => return error_response(&e),
    };
    let previous = match req.previous_stones {
        Some(ref s) => match build_board(req.width, req.height, s) {
            Ok(b) => Some(b),
            Err(e) => return error_response(&e),
        },
        None => None,
    };
    let color = match parse_color(&req.current_player) {
        Ok(c) => c,
        Err(e) => return error_response(&e),
    };
    let chosen = pick_move(&board, color, previous.as_ref(), req.komi, playouts);
    let response = match chosen {
        Some((x, y)) => GoMoveResponse::Play { x, y },
        None => GoMoveResponse::Pass,
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

fn error_response(msg: &str) -> Response<String> {
    Response::builder()
        .status(StatusCode::BAD_REQUEST)
        .header("Access-Control-Allow-Origin", "*")
        .header("Access-Control-Allow-Headers", "*")
        .header("Content-Type", "text/plain")
        .body(String::from(msg))
        .unwrap()
}
