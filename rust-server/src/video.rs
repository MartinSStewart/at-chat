//! Reads the pixel dimensions of a video file out of its container header.
//!
//! The `image` crate gives us the size of an image without decoding a whole
//! frame, but it doesn't know about video containers. The dimensions of a video
//! live in a small header near the start of the file, so rather than pulling in
//! a decoder we read them out of the container.
//!
//! Two container families are covered, which is what browsers will play:
//! `MP4`/`QuickTime` by way of `re_mp4`, and `WebM`/Matroska by way of
//! `matroska-demuxer`.
//!
//! These files are uploaded by users, so both parsers are only ever handed the
//! bytes and asked for a result. Anything malformed has to come back as an
//! error, never as a panic or a wild allocation.

/// Reads the pixel dimensions of a video, or `None` if the bytes aren't a video
/// container we understand.
pub fn video_dimensions(bytes: &[u8]) -> Option<(u32, u32)> {
    match mp4_dimensions(bytes) {
        Some(dimensions) => Some(dimensions),
        None => matroska_dimensions(bytes),
    }
}

/// Reads the dimensions of the first video track of an `MP4`.
///
/// The track header carries the transformation matrix the track is displayed
/// with. Phone cameras record in landscape and store a rotation in that matrix,
/// so a portrait video has landscape dimensions in its header that only come out
/// the right way around once the rotation is applied.
fn mp4_dimensions(bytes: &[u8]) -> Option<(u32, u32)> {
    let mp4: re_mp4::Mp4 = re_mp4::Mp4::read_bytes(bytes).ok()?;

    mp4.tracks().values().find_map(|track| {
        if track.kind != Some(re_mp4::TrackKind::Video) {
            return None;
        }

        let width = u32::from(track.width);
        let height = u32::from(track.height);

        if width == 0 || height == 0 {
            return None;
        }

        // The matrix is {a, b, u, c, d, v, x, y, w}, where a and d scale and b
        // and c rotate. A quarter turn zeroes the scale entries and fills in the
        // rotation entries, which is exactly when the width and the height are
        // swapped on screen.
        let matrix = &track.trak(&mp4).tkhd.matrix;
        let is_quarter_turn: bool =
            matrix.a == 0 && matrix.d == 0 && matrix.b != 0 && matrix.c != 0;

        if is_quarter_turn {
            Some((height, width))
        } else {
            Some((width, height))
        }
    })
}

/// Reads the dimensions of the first video track of a `WebM` or Matroska file.
fn matroska_dimensions(bytes: &[u8]) -> Option<(u32, u32)> {
    let matroska = matroska_demuxer::MatroskaFile::open(std::io::Cursor::new(bytes)).ok()?;

    matroska.tracks().iter().find_map(|track| {
        let video = track.video()?;

        // The display size is what the video should be shown at, which is what a
        // stretched or anamorphic video needs. It is optional, and only a size at
        // all when the display unit says pixels: the other units describe an
        // aspect ratio or a physical size, neither of which is what we want.
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

        Some((u32::try_from(width).ok()?, u32::try_from(height).ok()?))
    })
}

#[cfg(test)]
mod tests {
    use super::video_dimensions;

    /// The sample files live next to the tests so that they are read the same
    /// way whichever directory the tests are run from.
    fn sample(name: &str) -> Vec<u8> {
        let path = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("tests/samples")
            .join(name);

        std::fs::read(&path).unwrap_or_else(|error| panic!("could not read {path:?}: {error}"))
    }

    #[test]
    fn reads_mp4_dimensions() {
        assert_eq!(
            video_dimensions(&sample("landscape.mp4")),
            Some((640, 360)),
            "the dimensions should be read from the track header"
        );
    }

    #[test]
    fn reads_webm_dimensions() {
        assert_eq!(
            video_dimensions(&sample("landscape.webm")),
            Some((640, 360)),
            "the dimensions should be read from the video track"
        );
    }

    #[test]
    fn prefers_webm_display_dimensions() {
        assert_eq!(
            video_dimensions(&sample("anamorphic.webm")),
            Some((480, 360)),
            "a video with a display size should report the size it is shown at, \
             not the 640x360 it is coded at"
        );
    }

    #[test]
    fn applies_mp4_rotation_to_the_dimensions() {
        assert_eq!(
            video_dimensions(&sample("rotated.mp4")),
            Some((360, 640)),
            "a quarter turn should swap the width and the height"
        );
    }

    #[test]
    fn ignores_mp4_files_with_no_video_track() {
        assert_eq!(
            video_dimensions(&sample("audio_only.mp4")),
            None,
            "an audio track has no dimensions to report"
        );
    }

    #[test]
    fn returns_nothing_for_files_that_are_not_video() {
        assert_eq!(
            video_dimensions(b"this is a plain text file, not a video"),
            None,
            "text is not a video container"
        );
        assert_eq!(
            video_dimensions(&[]),
            None,
            "an empty file has no dimensions"
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

        assert_eq!(
            video_dimensions(&bytes),
            None,
            "an oversized declaration should be refused, not believed"
        );
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

                let _ = video_dimensions(&damaged);
            }
        }
    }
}
