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
    /// How long the video runs, in milliseconds.
    pub duration_ms: Option<u64>,
    /// When the file says it was recorded, as milliseconds since the Unix epoch.
    pub created_at_ms: Option<i64>,
    /// The turn or flip the video is displayed with, numbered the way EXIF does
    /// it so that images and videos are read the same way. Already applied to
    /// `video_size`. `1` means shown as recorded, which is also what a container
    /// that cannot express a transform reports.
    pub orientation: u8,
    /// How the container names the video codec. `MP4` files use the RFC 6381
    /// spelling such as `avc1.42E01E`, Matroska files their own such as `V_VP9`.
    pub codec: Option<String>,
    pub title: Option<String>,
    /// Where the recording was made, which only `MP4` has somewhere standard to
    /// put.
    pub gps_location: Option<crate::Location>,
}

/// Shown as recorded, the EXIF numbering for no transform at all.
const NO_TRANSFORM: u8 = 1;

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

    let matrix = &track.trak(&mp4).tkhd.matrix;
    let orientation = orientation_from_matrix(matrix.a, matrix.b, matrix.c, matrix.d);

    let movie = &mp4.moov.mvhd;

    let created_at_ms: Option<i64> = i64::try_from(movie.creation_time)
        .ok()
        .and_then(|seconds| seconds.checked_mul(1000))
        .and_then(|milliseconds| milliseconds.checked_sub(MP4_EPOCH_OFFSET_MS))
        .and_then(plausible_timestamp);

    // The track counts its length in its own time units, so many of them to the
    // second. A fragmented file leaves the header empty and `re_mp4` adds the
    // samples up instead, so there is a length here either way.
    let duration_ms: Option<u64> = if track.duration > 0 && track.timescale > 0 {
        Some(track.duration.saturating_mul(1000) / track.timescale)
    } else {
        None
    };

    Some(VideoMetadata {
        video_size: if turns_a_quarter(orientation) {
            (height, width)
        } else {
            (width, height)
        },
        duration_ms,
        created_at_ms,
        orientation,
        codec: track.codec_string(&mp4),
        title: None,
        gps_location: mp4_gps_location(bytes),
    })
}

/// Turns an `MP4` display matrix into the EXIF orientation number.
///
/// The matrix is {a, b, u, c, d, v, x, y, w}, and a point is placed at
/// `(a * x + c * y, b * x + d * y)` plus a translation. Only the four entries
/// that scale and rotate matter for naming the transform, and only their signs
/// within those: a and d alone is a flip about one axis or the other, b and c
/// alone swaps the axes over.
///
/// EXIF numbers the eight results by where the first row and the first column of
/// the stored picture end up, which is the same thing said differently, so the
/// two notations line up one to one.
fn orientation_from_matrix(a: i32, b: i32, c: i32, d: i32) -> u8 {
    match (a.signum(), b.signum(), c.signum(), d.signum()) {
        (1, 0, 0, 1) => 1,   // as recorded
        (-1, 0, 0, 1) => 2,  // mirrored left to right
        (-1, 0, 0, -1) => 3, // turned upside down
        (1, 0, 0, -1) => 4,  // mirrored top to bottom
        (0, 1, 1, 0) => 5,   // mirrored across the leading diagonal
        (0, 1, -1, 0) => 6,  // a quarter turn clockwise, how a phone holds portrait
        (0, -1, -1, 0) => 7, // mirrored across the other diagonal
        (0, -1, 1, 0) => 8,  // a quarter turn anticlockwise
        // A scale, a skew, or an empty matrix. None of those have a name here,
        // and guessing at one would be worse than saying the picture stands as
        // it was recorded.
        _ => NO_TRANSFORM,
    }
}

/// Whether an orientation swaps the width and the height over, which is the four
/// that put the first row of the picture down one of its sides.
fn turns_a_quarter(orientation: u8) -> bool {
    matches!(orientation, 5..=8)
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

    // The length is counted in units of the timestamp scale, which is itself a
    // number of nanoseconds, so a file written with an unusual scale reads the
    // same way as any other.
    let duration_ms: Option<u64> = match info.duration() {
        Some(duration) if duration > 0.0 && duration.is_finite() => {
            Some((duration * info.timestamp_scale().get() as f64 / 1_000_000.0) as u64)
        }
        _ => None,
    };

    let created_at_ms: Option<i64> = info
        .date_utc()
        .map(|nanoseconds| nanoseconds / 1_000_000 + MATROSKA_EPOCH_OFFSET_MS)
        .and_then(plausible_timestamp);

    let video_size: (u32, u32) = (u32::try_from(width).ok()?, u32::try_from(height).ok()?);
    let codec: String = track.codec_id().to_owned();
    let title: Option<String> = info.title().map(str::to_owned);

    Some(VideoMetadata {
        video_size,
        duration_ms,
        created_at_ms,
        // Matroska has no field for this. A file can be flagged as a projection
        // for 360 degree video, but that is a different thing to a photograph
        // taken sideways, and nothing here writes one.
        orientation: NO_TRANSFORM,
        codec: Some(codec),
        title,
        // Matroska has no standard element for a location either.
        gps_location: None,
    })
}

/// Reads where an `MP4` says it was recorded.
///
/// `re_mp4` keeps the boxes it knows how to interpret and drops the rest, and
/// the location is one it drops, so this goes and finds it. It is stored under
/// `moov/udta` in a box named with a copyright sign, holding an ISO 6709 string.
fn mp4_gps_location(bytes: &[u8]) -> Option<crate::Location> {
    let user_data = find_box(find_box(bytes, b"moov")?, b"udta")?;
    let location = find_box(user_data, &[0xA9, b'x', b'y', b'z'])?;

    // A length, a language code, and then the string itself. The length has been
    // known to disagree with the box, so it is a hint rather than the authority.
    let length = usize::from(u16::from_be_bytes(location.get(0..2)?.try_into().ok()?));
    let text = location
        .get(4..4 + length)
        .or_else(|| location.get(4..))
        .and_then(|slice| std::str::from_utf8(slice).ok())?;

    parse_iso6709(text)
}

/// Hands back the contents of the first box of the given type, out of a run of
/// `MP4` boxes.
///
/// Sizes are checked against what is actually there before being used, so a box
/// claiming to be larger than the file ends the search rather than being
/// believed.
fn find_box<'a>(data: &'a [u8], box_type: &[u8; 4]) -> Option<&'a [u8]> {
    let mut offset: usize = 0;

    while offset + 8 <= data.len() {
        let declared = u32::from_be_bytes(data.get(offset..offset + 4)?.try_into().ok()?);
        let is_wanted: bool = data.get(offset + 4..offset + 8)? == box_type;

        let (header, size): (usize, usize) = match declared {
            // A size of one means the real size is the 64 bit value that follows.
            1 => {
                let large = u64::from_be_bytes(data.get(offset + 8..offset + 16)?.try_into().ok()?);
                (16, usize::try_from(large).ok()?)
            }
            // A size of zero means the box runs to the end of the file.
            0 => (8, data.len() - offset),
            _ => (8, declared as usize),
        };

        if size < header {
            return None;
        }

        let end: usize = offset
            .checked_add(size)
            .filter(|end2| *end2 <= data.len())?;

        if is_wanted {
            return data.get(offset + header..end);
        }

        offset = end;
    }

    None
}

/// Reads a latitude and longitude out of an ISO 6709 string such as
/// `+37.7749-122.4194+010.000/`, which is how `MP4` writes down where a
/// recording was made. Altitude, when there is one, is ignored.
fn parse_iso6709(text: &str) -> Option<crate::Location> {
    let trimmed: &str = text.trim().trim_end_matches('/');

    // Every part carries its own sign, so a sign is where the next part starts.
    let mut parts: Vec<&str> = Vec::new();
    let mut start: usize = 0;

    for (index, character) in trimmed.char_indices() {
        if index > start && (character == '+' || character == '-') {
            parts.push(trimmed.get(start..index)?);
            start = index;
        }
    }

    parts.push(trimmed.get(start..)?);

    let lat: f64 = signed_degrees(parts.first()?, 2)?;
    let lon: f64 = signed_degrees(parts.get(1)?, 3)?;

    if (-90.0..=90.0).contains(&lat) && (-180.0..=180.0).contains(&lon) {
        Some(crate::Location { lat, lon })
    } else {
        None
    }
}

/// Reads one signed part of an ISO 6709 string.
///
/// Degrees are written with a fixed number of digits, and any whole digits past
/// that are minutes and then seconds. So the width of the whole number is what
/// tells `+37.7749`, `+3746.494` and `+374629.6` apart, all three of which are
/// the same latitude.
fn signed_degrees(part: &str, degree_digits: usize) -> Option<f64> {
    let sign: f64 = if part.starts_with('-') { -1.0 } else { 1.0 };

    if !part.starts_with('-') && !part.starts_with('+') {
        return None;
    }

    let digits: &str = part.get(1..)?;
    let whole: &str = match digits.find('.') {
        Some(point) => digits.get(..point)?,
        None => digits,
    };

    let degrees: f64 = whole.get(..degree_digits)?.parse().ok()?;

    let smaller: f64 = match whole.len().checked_sub(degree_digits)? {
        0 => digits.get(degree_digits..)?.parse::<f64>().unwrap_or(0.0),
        2 => digits.get(degree_digits..)?.parse::<f64>().ok()? / 60.0,
        4 => {
            let minutes: f64 = digits.get(degree_digits..degree_digits + 2)?.parse().ok()?;
            let seconds: f64 = digits.get(degree_digits + 2..)?.parse().ok()?;
            minutes / 60.0 + seconds / 3600.0
        }
        _ => return None,
    };

    Some(sign * (degrees + smaller))
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
        assert_eq!(mp4.duration_ms, Some(10_000), "the sample runs ten seconds");
        assert_eq!(mp4.codec.as_deref(), Some("avc1.64001F"), "h.264 track");
        assert_eq!(mp4.orientation, 1, "the sample stands as recorded");
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
        assert_eq!(
            webm.duration_ms,
            Some(10_000),
            "the same ten seconds as the MP4 sample"
        );
        assert_eq!(webm.codec.as_deref(), Some("V_VP9"), "vp9 track");
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
        assert_eq!(
            rotated.orientation, 6,
            "and be named the way EXIF names a quarter turn clockwise"
        );
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
            r#"{"video_size":[640,360],"duration_ms":10000,"created_at_ms":1710505845000,"orientation":1,"codec":"avc1.64001F","title":null,"gps_location":{"lat":59.3293,"lon":18.0686}}"#,
            "changing this breaks whoever is decoding it"
        );
    }

    #[test]
    fn reads_where_an_mp4_was_recorded() {
        let location = metadata("landscape.mp4")
            .gps_location
            .expect("the sample has a location box");

        assert_eq!((location.lat, location.lon), (59.3293, 18.0686));
    }

    /// Every transform an `MP4` matrix can name, against the EXIF number for the
    /// same thing. The entries are whole numbers here; real files write them as
    /// fixed point, which does not change any of the signs.
    #[test]
    fn names_every_orientation_a_matrix_can_hold() {
        use super::orientation_from_matrix;

        assert_eq!(orientation_from_matrix(1, 0, 0, 1), 1, "as recorded");
        assert_eq!(orientation_from_matrix(-1, 0, 0, 1), 2, "mirrored sideways");
        assert_eq!(orientation_from_matrix(-1, 0, 0, -1), 3, "upside down");
        assert_eq!(
            orientation_from_matrix(1, 0, 0, -1),
            4,
            "mirrored top to toe"
        );
        assert_eq!(
            orientation_from_matrix(0, 1, 1, 0),
            5,
            "across one diagonal"
        );
        assert_eq!(
            orientation_from_matrix(0, 1, -1, 0),
            6,
            "a quarter turn right"
        );
        assert_eq!(orientation_from_matrix(0, -1, -1, 0), 7, "across the other");
        assert_eq!(
            orientation_from_matrix(0, -1, 1, 0),
            8,
            "a quarter turn left"
        );

        assert_eq!(
            orientation_from_matrix(0, 0, 0, 0),
            1,
            "an empty matrix names no transform, so the picture stands as it is"
        );
        assert_eq!(
            orientation_from_matrix(1, 1, 1, 1),
            1,
            "nor does a skew, which is not one of the eight"
        );
    }

    /// The same spot in Stockholm written the three ways ISO 6709 allows, since
    /// how many digits come before the decimal point is the only thing saying
    /// which of the three a string is.
    #[test]
    fn reads_the_three_ways_a_location_can_be_written() {
        use super::parse_iso6709;

        for (label, text) in [
            ("degrees", "+59.3293+018.0686/"),
            ("degrees and minutes", "+5919.758+01804.116/"),
            ("degrees, minutes and seconds", "+591945.5+0180406.9/"),
        ] {
            let location = parse_iso6709(text).unwrap_or_else(|| panic!("{label} should parse"));

            assert!(
                (location.lat - 59.3293).abs() < 0.001 && (location.lon - 18.0686).abs() < 0.001,
                "{label} gave {location:?}, which is not where Stockholm is"
            );
        }

        assert!(
            parse_iso6709("+59.3293+018.0686+010.500/").is_some(),
            "an altitude on the end is allowed, and ignored"
        );
        assert!(
            parse_iso6709("-33.8688+151.2093/").is_some(),
            "the southern hemisphere is not an error"
        );
    }

    #[test]
    fn refuses_locations_that_are_not_locations() {
        use super::parse_iso6709;

        for text in [
            "",
            "/",
            "+59.3293/",             // a latitude on its own
            "59.3293+018.0686/",     // no sign, so no telling where it starts
            "+99.9999+018.0686/",    // no such latitude
            "+59.3293+999.9999/",    // no such longitude
            "+not.a.number+018.06/", // not a number at all
        ] {
            assert!(
                parse_iso6709(text).is_none(),
                "{text:?} should not be read as a location"
            );
        }
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

    /// `matroska-demuxer` 0.8.1 negates a block timestamp to take its size,
    /// which overflows on the smallest number that field can hold. Everything
    /// read here comes out of the header, so a file carrying such a block is
    /// read the same as any other, and it stays that way only for as long as
    /// nothing walks the blocks.
    #[test]
    fn survives_the_smallest_block_timestamp() {
        let mut bytes = sample("landscape.webm");

        // Every block in the sample is a simple block header, a length, a track
        // number, and then a two byte timestamp. The search starts at the
        // cluster so that a stray pair of bytes earlier on cannot pass for one.
        let cluster = bytes
            .windows(4)
            .position(|window| window == [0x1F, 0x43, 0xB6, 0x75])
            .expect("the sample has a cluster");
        let block = cluster
            + bytes
                .get(cluster..)
                .and_then(|rest| rest.windows(2).position(|window| window == [0xA3, 0x01]))
                .expect("the cluster is built out of simple blocks");
        let timestamp = block + 2 + 7 + 1;

        bytes[timestamp..timestamp + 2].copy_from_slice(&i16::MIN.to_be_bytes());

        assert_eq!(
            video_metadata(&bytes)
                .expect("the file is still a video")
                .duration_ms,
            Some(10_000),
            "the header still says how long it runs"
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

                let _ = video_metadata(&damaged);
            }
        }
    }
}
