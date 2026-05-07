//! Modernised port of iomrascalai (<https://github.com/ujh/iomrascalai>),
//! GPL-3.0-or-later. Brought up to stable Rust by replacing
//! `time::PreciseTime` with `std::time::Instant`, the `mpsc_select!` macro
//! with `crossbeam-channel::select!`, the removed `rand::XorShiftRng` /
//! `gen_range(a, b)` API with `rand 0.10` equivalents, and removing
//! nightly-only attributes. Behaviour is intentionally unchanged.

pub mod board;
pub mod config;
pub mod engine;
pub mod game;
pub mod ownership;
pub mod patterns;
pub mod playout;
pub mod ruleset;
pub mod score;
pub mod timer;
