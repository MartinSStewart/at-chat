//! Reads what a video file says about itself in its container header.
//!
//! The `image` crate gives us the size of an image without decoding a whole
//! frame, but it doesn't know about video containers. What a video has to say
//! about itself lives in a small header near the start of the file, so rather
//! than pulling in a decoder we read it out of the container.
//!
//! Two container families are covered, which is what browsers will play:
//! `MP4`/`QuickTime` by way of `re_mp4`, and `WebM`/Matroska by way of
//! `matroska-demuxer`.
//!
//! These files are uploaded by users, so both parsers are only ever handed the
//! bytes and asked for a result. Anything malformed has to come back as an
//! error, never as a panic or a wild allocation.

use serde::Serialize;

#[derive(Debug, Serialize)]
pub struct VideoMetadata {
    /// The size the video is displayed at, with any rotation already applied.
    pub video_size: (u32, u32),
    pub duration_ms: Option<u64>,
    /// When the file says it was recorded, as milliseconds since the Unix epoch.
    pub created_at_ms: Option<i64>,
    /// A quarter turn or half turn the video is displayed with, in degrees. Only
    /// `MP4` stores this; it is already applied to `video_size`.
    pub rotation: Option<u16>,
    pub frame_rate: Option<f32>,
    /// How the container names the video codec. `MP4` files use the RFC 6381
    /// spelling such as `avc1.42E01E`, Matroska files their own such as `V_VP9`.
    pub codec: Option<String>,
    pub title: Option<String>,
}

/// Reads the metadata of a video, or `None` if the bytes aren't a video
/// container we understand or hold no video track.
pub fn video_metadata(bytes: &[u8]) -> Option<VideoMetadata> {
    match mp4_metadata(bytes) {
        Some(metadata) => Some(metadata),
        None => matroska_metadata(bytes),
    }
}

/// Seconds from the start of 1904, which `MP4` counts from, to the Unix epoch.
const MP4_EPOCH_OFFSET_MS: i64 = 2_082_844_800_000;

/// Seconds from the start of 2001, which Matroska counts from, to the Unix epoch.
const MATROSKA_EPOCH_OFFSET_MS: i64 = 978_307_200_000;

/// Containers carry a creation time whether or not anything ever set one, so it
/// is routinely zero, and files written with a wrong epoch are common enough to
/// be worth discarding. Anything outside living memory of digital video is
/// treated as absent rather than passed on as fact.
fn plausible_timestamp(unix_ms: i64) -> Option<i64> {
    // The start of 1990 up to the start of 2100.
    if (631_152_000_000..4_102_444_800_000).contains(&unix_ms) {
        Some(unix_ms)
    } else {
        None
    }
}

/// Reads the metadata of the first video track of an `MP4`.
fn mp4_metadata(bytes: &[u8]) -> Option<VideoMetadata> {
    let mp4: re_mp4::Mp4 = re_mp4::Mp4::read_bytes(bytes).ok()?;

    let track = mp4
        .tracks()
        .values()
        .find(|track| track.kind == Some(re_mp4::TrackKind::Video))?;

    let width = u32::from(track.width);
    let height = u32::from(track.height);

    if width == 0 || height == 0 {
        return None;
    }

    // The track matrix is {a, b, u, c, d, v, x, y, w}, where a and d scale and b
    // and c rotate. A quarter turn zeroes the scale entries and fills in the
    // rotation entries, which is exactly when the width and the height are
    // swapped on screen. A half turn negates the scale entries instead, which
    // turns the picture over without changing its shape.
    let matrix = &track.trak(&mp4).tkhd.matrix;
    let is_quarter_turn: bool = matrix.a == 0 && matrix.d == 0 && matrix.b != 0 && matrix.c != 0;
    let is_half_turn: bool = matrix.a < 0 && matrix.d < 0;

    let rotation: Option<u16> = if is_quarter_turn {
        // b positive is a turn to the right, b negative one to the left.
        Some(if matrix.b > 0 { 90 } else { 270 })
    } else if is_half_turn {
        Some(180)
    } else {
        None
    };

    let movie = &mp4.moov.mvhd;

    let duration_ms: Option<u64> = match (movie.duration, u64::from(movie.timescale)) {
        (0, _) | (_, 0) => None,
        (duration, timescale) => Some(duration.saturating_mul(1000) / timescale),
    };

    let created_at_ms: Option<i64> = i64::try_from(movie.creation_time)
        .ok()
        .and_then(|seconds| seconds.checked_mul(1000))
        .and_then(|milliseconds| milliseconds.checked_sub(MP4_EPOCH_OFFSET_MS))
        .and_then(plausible_timestamp);

    // The sample count over the length of the track, which is the average rate
    // rather than a declared one. Variable frame rate video has no single answer
    // and this is the closest to it.
    let frame_rate: Option<f32> = match (track.duration, track.timescale) {
        (0, _) | (_, 0) => None,
        (duration, timescale) => {
            let seconds = duration as f64 / timescale as f64;
            Some((track.samples.len() as f64 / seconds) as f32)
        }
    };

    Some(VideoMetadata {
        video_size: if is_quarter_turn {
            (height, width)
        } else {
            (width, height)
        },
        duration_ms,
        created_at_ms,
        rotation,
        frame_rate,
        codec: track.codec_string(&mp4),
        title: None,
    })
}

/// Reads the metadata of the first video track of a `WebM` or Matroska file.
fn matroska_metadata(bytes: &[u8]) -> Option<VideoMetadata> {
    let matroska = matroska_demuxer::MatroskaFile::open(std::io::Cursor::new(bytes)).ok()?;

    let track = matroska
        .tracks()
        .iter()
        .find(|track| track.video().is_some())?;
    let video = track.video()?;

    // The display size is what the video should be shown at, which is what a
    // stretched or anamorphic video needs. It is optional, and only a size at
    // all when the display unit says pixels: the other units describe an aspect
    // ratio or a physical size, neither of which is what we want.
    let display_size: Option<(u64, u64)> = match video.display_unit() {
        Some(matroska_demuxer::DisplayUnit::Pixels) | None => {
            match (video.display_width(), video.display_height()) {
                (Some(width), Some(height)) => Some((width.get(), height.get())),
                _ => None,
            }
        }
        Some(_) => None,
    };

    let (width, height): (u64, u64) = match display_size {
        Some(display_size2) => display_size2,
        None => (video.pixel_width().get(), video.pixel_height().get()),
    };

    let info = matroska.info();

    // Durations are counted in ticks whose length the file gets to choose, given
    // in nanoseconds.
    let duration_ms: Option<u64> = info.duration().and_then(|ticks| {
        let nanoseconds = ticks * info.timestamp_scale().get() as f64;
        let milliseconds = nanoseconds / 1_000_000.0;

        if milliseconds.is_finite() && milliseconds >= 0.0 {
            Some(milliseconds as u64)
        } else {
            None
        }
    });

    let created_at_ms: Option<i64> = info
        .date_utc()
        .map(|nanoseconds| nanoseconds / 1_000_000 + MATROSKA_EPOCH_OFFSET_MS)
        .and_then(plausible_timestamp);

    // Unlike MP4 this is a declared frame duration rather than a measured one,
    // and it is only present on constant frame rate files.
    let frame_rate: Option<f32> = track
        .default_duration()
        .map(|nanoseconds| (1_000_000_000.0 / nanoseconds.get() as f64) as f32);

    Some(VideoMetadata {
        video_size: (u32::try_from(width).ok()?, u32::try_from(height).ok()?),
        duration_ms,
        created_at_ms,
        rotation: None,
        frame_rate,
        codec: Some(track.codec_id().to_owned()),
        title: info.title().map(str::to_owned),
    })
}

#[cfg(test)]
mod tests {
    use super::{VideoMetadata, video_metadata};

    /// The sample files live next to the tests so that they are read the same
    /// way whichever directory the tests are run from.
    fn sample(name: &str) -> Vec<u8> {
        let path = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("tests/samples")
            .join(name);

        std::fs::read(&path).unwrap_or_else(|error| panic!("could not read {path:?}: {error}"))
    }

    fn metadata(name: &str) -> VideoMetadata {
        video_metadata(&sample(name)).unwrap_or_else(|| panic!("{name} should have metadata"))
    }

    #[test]
    fn reads_mp4_metadata() {
        let mp4 = metadata("landscape.mp4");

        assert_eq!(mp4.video_size, (640, 360), "size from the track header");
        assert_eq!(mp4.duration_ms, Some(10_000), "the sample is ten seconds");
        assert_eq!(mp4.codec.as_deref(), Some("avc1.64001F"), "h.264 track");
        assert_eq!(mp4.rotation, None, "the sample is not rotated");
        assert_eq!(
            mp4.frame_rate.map(f32::round),
            Some(30.0),
            "the sample runs at thirty frames a second"
        );
        assert_eq!(
            mp4.created_at_ms,
            Some(1_710_505_845_000),
            "2024-03-15T12:30:45Z, counted from 1904 in the file itself"
        );
    }

    #[test]
    fn reads_webm_metadata() {
        let webm = metadata("landscape.webm");

        assert_eq!(webm.video_size, (640, 360), "size from the video track");
        assert_eq!(webm.duration_ms, Some(10_000), "the sample is ten seconds");
        assert_eq!(webm.codec.as_deref(), Some("V_VP9"), "vp9 track");
        assert_eq!(
            webm.frame_rate.map(f32::round),
            Some(30.0),
            "the sample runs at thirty frames a second"
        );
        assert_eq!(
            webm.created_at_ms,
            Some(1_710_505_845_000),
            "the same instant as the MP4 sample, though counted from 2001 here"
        );
    }

    #[test]
    fn prefers_webm_display_dimensions() {
        assert_eq!(
            metadata("anamorphic.webm").video_size,
            (480, 360),
            "a video with a display size should report the size it is shown at, \
             not the 640x360 it is coded at"
        );
    }

    #[test]
    fn applies_mp4_rotation_to_the_dimensions() {
        let rotated = metadata("rotated.mp4");

        assert_eq!(
            rotated.video_size,
            (360, 640),
            "a quarter turn should swap the width and the height"
        );
        assert_eq!(rotated.rotation, Some(90), "and be reported alongside it");
    }

    #[test]
    fn ignores_mp4_files_with_no_video_track() {
        assert!(
            video_metadata(&sample("audio_only.mp4")).is_none(),
            "an audio track has nothing to report"
        );
    }

    #[test]
    fn returns_nothing_for_files_that_are_not_video() {
        assert!(
            video_metadata(b"this is a plain text file, not a video").is_none(),
            "text is not a video container"
        );
        assert!(
            video_metadata(&[]).is_none(),
            "an empty file has nothing to report"
        );
    }

    /// A container is free to claim an element is larger than the file that
    /// holds it. A parser that believes the claim and allocates that much up
    /// front aborts the whole process, which a fifty byte upload should never be
    /// able to do.
    #[test]
    fn survives_oversized_declarations() {
        fn element(id: &[u8], payload: &[u8]) -> Vec<u8> {
            let mut bytes: Vec<u8> = id.to_vec();
            bytes.push(0x01);
            bytes.extend_from_slice(&(payload.len() as u64).to_be_bytes()[1..8]);
            bytes.extend_from_slice(payload);
            bytes
        }

        // A track entry whose codec data claims to be some 70 petabytes long.
        let mut bomb: Vec<u8> = vec![0x63, 0xA2, 0x01];
        bomb.extend_from_slice(&[0xFC, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD]);

        let mut bytes: Vec<u8> = element(&[0x1A, 0x45, 0xDF, 0xA3], &[]);
        bytes.extend_from_slice(&element(
            &[0x18, 0x53, 0x80, 0x67],
            &element(&[0x16, 0x54, 0xAE, 0x6B], &element(&[0xAE], &bomb)),
        ));

        assert!(
            video_metadata(&bytes).is_none(),
            "an oversized declaration should be refused, not believed"
        );
    }

    /// The upload endpoint serialises this straight into its response, so the
    /// field names are what a client decodes against.
    #[test]
    fn serialises_to_the_shape_clients_read() {
        assert_eq!(
            serde_json::to_string(&metadata("landscape.mp4")).unwrap(),
            r#"{"video_size":[640,360],"duration_ms":10000,"created_at_ms":1710505845000,"rotation":null,"frame_rate":30.0,"codec":"avc1.64001F","title":null}"#,
            "changing this breaks whoever is decoding it"
        );
    }

    /// A creation time of zero means nothing ever set one, and a file written
    /// with the wrong epoch lands centuries away from now. Neither should be
    /// passed on as if it were a real date.
    #[test]
    fn discards_implausible_creation_times() {
        let mut bytes = sample("landscape.mp4");
        let mvhd = bytes
            .windows(4)
            .position(|window| window == b"mvhd")
            .expect("the sample has a movie header")
            - 4;

        for (label, creation_time) in [
            ("never set", 0u32),
            ("still in 1904", 1),
            (
                "a unix timestamp written as if it were an MP4 one",
                1_710_505_845,
            ),
        ] {
            bytes[mvhd + 12..mvhd + 16].copy_from_slice(&creation_time.to_be_bytes());

            assert_eq!(
                video_metadata(&bytes)
                    .expect("the file is still a video")
                    .created_at_ms,
                None,
                "a creation time that is {label} should be dropped"
            );
        }
    }

    /// Uploads are untrusted, so a corrupt or hostile file has to come back as
    /// `None` rather than take the request down with it.
    #[test]
    fn survives_damaged_files() {
        let mut rng: u64 = 0x243F_6A88_85A3_08D3;
        let mut next = move || {
            rng ^= rng << 13;
            rng ^= rng >> 7;
            rng ^= rng << 17;
            rng
        };

        for name in ["landscape.mp4", "landscape.webm"] {
            let bytes = sample(name);

            for _ in 0..500 {
                let cut = (next() as usize) % (bytes.len() + 1);
                let mut damaged = bytes[..cut].to_vec();

                if !damaged.is_empty() {
                    let index = (next() as usize) % damaged.len();
                    damaged[index] = next() as u8;
                }

                let _ = video_metadata(&damaged);
            }
        }
    }
}
