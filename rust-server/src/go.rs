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
use rand::{Rng, RngExt};
use serde::{Deserialize, Serialize};

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

    /// True if the chain containing (x, y) has at least one empty neighbor.
    /// `visited` is reused between calls; the caller must zero it first.
    fn chain_has_liberty(&self, x: usize, y: usize, visited: &mut [bool]) -> bool {
        let color = match self.get(x, y) {
            Some(c) => c,
            None => return false,
        };
        let start = self.idx(x, y);
        // Scratch stack of indices.
        let mut stack: [usize; 25 * 25] = [0; 25 * 25];
        let mut top = 0usize;
        stack[top] = start;
        top += 1;
        visited[start] = true;
        while top > 0 {
            top -= 1;
            let i = stack[top];
            let cy = i / self.width;
            let cx = i - cy * self.width;
            for (nx, ny) in self.neighbors(cx, cy) {
                let ni = self.idx(nx, ny);
                match self.cells[ni] {
                    None => return true,
                    Some(c) if c == color && !visited[ni] => {
                        visited[ni] = true;
                        stack[top] = ni;
                        top += 1;
                    }
                    _ => {}
                }
            }
        }
        false
    }

    /// Remove the captured chain rooted at (x, y) (assumed to have no
    /// liberties) and return the number of stones removed.
    fn remove_chain(&mut self, x: usize, y: usize) -> usize {
        let color = match self.get(x, y) {
            Some(c) => c,
            None => return 0,
        };
        let mut count = 0usize;
        let mut stack: [usize; 25 * 25] = [0; 25 * 25];
        let mut top = 0usize;
        stack[top] = self.idx(x, y);
        top += 1;
        while top > 0 {
            top -= 1;
            let i = stack[top];
            if self.cells[i] != Some(color) {
                continue;
            }
            self.cells[i] = None;
            count += 1;
            let cy = i / self.width;
            let cx = i - cy * self.width;
            for (nx, ny) in self.neighbors(cx, cy) {
                let ni = self.idx(nx, ny);
                if self.cells[ni] == Some(color) {
                    stack[top] = ni;
                    top += 1;
                }
            }
        }
        count
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
        visited: &mut Vec<bool>,
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
                visited.iter_mut().for_each(|v| *v = false);
                if !next.chain_has_liberty(nx, ny, visited) {
                    captured += next.remove_chain(nx, ny);
                }
            }
        }
        visited.iter_mut().for_each(|v| *v = false);
        if !next.chain_has_liberty(x, y, visited) {
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
    fn area_score(&self, komi: f32, visited: &mut [bool]) -> f32 {
        visited.iter_mut().for_each(|v| *v = false);
        let mut black = 0i32;
        let mut white = 0i32;
        let mut stack: [usize; 25 * 25] = [0; 25 * 25];
        for y in 0..self.height {
            for x in 0..self.width {
                let i0 = self.idx(x, y);
                match self.cells[i0] {
                    Some(Color::Black) => black += 1,
                    Some(Color::White) => white += 1,
                    None => {
                        if visited[i0] {
                            continue;
                        }
                        visited[i0] = true;
                        let mut top = 0usize;
                        stack[top] = i0;
                        top += 1;
                        let mut size = 0i32;
                        let mut touches_black = false;
                        let mut touches_white = false;
                        while top > 0 {
                            top -= 1;
                            let i = stack[top];
                            size += 1;
                            let cy = i / self.width;
                            let cx = i - cy * self.width;
                            for (nx, ny) in self.neighbors(cx, cy) {
                                let ni = self.idx(nx, ny);
                                match self.cells[ni] {
                                    Some(Color::Black) => touches_black = true,
                                    Some(Color::White) => touches_white = true,
                                    None => {
                                        if !visited[ni] {
                                            visited[ni] = true;
                                            stack[top] = ni;
                                            top += 1;
                                        }
                                    }
                                }
                            }
                        }
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

fn legal_moves(board: &Board, color: Color, previous: Option<&Board>) -> Vec<(usize, usize)> {
    let mut moves = Vec::new();
    let mut visited = vec![false; board.width * board.height];
    for y in 0..board.height {
        for x in 0..board.width {
            if board.get(x, y).is_some() {
                continue;
            }
            if board.is_eye(x, y, color) {
                continue;
            }
            if board.try_play(x, y, color, previous, &mut visited).is_some() {
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
    visited: &mut Vec<bool>,
) -> f32 {
    let mut board = start.clone();
    let mut previous: Option<Board> = None;
    let mut current = start_player;
    let mut consecutive_passes = 0u8;
    let mut empties: Vec<(usize, usize)> = Vec::with_capacity(board.width * board.height);
    for _ in 0..max_moves {
        empties.clear();
        for y in 0..board.height {
            for x in 0..board.width {
                if board.get(x, y).is_none() {
                    empties.push((x, y));
                }
            }
        }
        // Walk empties in a random order; first legal non-eye move wins.
        for i in (1..empties.len()).rev() {
            let j = rng.random_range(0..=i);
            empties.swap(i, j);
        }
        let mut played = false;
        for &(mx, my) in &empties {
            if board.is_eye(mx, my, current) {
                continue;
            }
            if let Some((next, _)) = board.try_play(mx, my, current, previous.as_ref(), visited) {
                previous = Some(board);
                board = next;
                consecutive_passes = 0;
                played = true;
                break;
            }
        }
        if !played {
            previous = Some(board.clone());
            consecutive_passes += 1;
            if consecutive_passes >= 2 {
                break;
            }
        }
        current = current.opposite();
    }
    board.area_score(komi, visited)
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
    let mut visited = vec![false; board.width * board.height];
    // Score for passing right now — the AI passes if no candidate beats it.
    let mut pass_total: f32 = 0.0;
    for _ in 0..playouts_per_move {
        pass_total += sign * random_playout(&mut rng, board, color.opposite(), komi, max_moves, &mut visited);
    }
    let pass_score = pass_total / playouts_per_move as f32;
    let mut best: Option<((usize, usize), f32)> = None;
    for (mx, my) in candidates {
        let (after, _) = match board.try_play(mx, my, color, previous, &mut visited) {
            Some(r) => r,
            None => continue,
        };
        let mut total: f32 = 0.0;
        for _ in 0..playouts_per_move {
            let s = random_playout(&mut rng, &after, color.opposite(), komi, max_moves, &mut visited);
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
    8
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
    let playouts = req.playouts_per_move.clamp(1, 200);
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
    let komi = req.komi;
    // Playouts are CPU-bound and can take seconds; run off the runtime thread
    // so concurrent requests don't pile up behind a single search.
    let chosen = match tokio::task::spawn_blocking(move || {
        pick_move(&board, color, previous.as_ref(), komi, playouts)
    })
    .await
    {
        Ok(c) => c,
        Err(_) => return error_response("AI worker panicked"),
    };
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
