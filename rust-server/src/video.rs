//! Reads the pixel dimensions of a video file straight out of its container.
//!
//! The `image` crate gives us the size of an image without decoding a whole
//! frame, but it doesn't know about video containers. The dimensions of a video
//! live in a small header near the start of the file, so rather than pulling in
//! a decoder we walk the container structure and read them out.
//!
//! Two container families are covered, which is what browsers will play:
//! `MP4`/`QuickTime` (ISO base media file format) and `WebM`/Matroska.

fn read_u16(data: &[u8], offset: usize) -> Option<u16> {
    Some(u16::from_be_bytes(
        data.get(offset..offset + 2)?.try_into().ok()?,
    ))
}

fn read_u32(data: &[u8], offset: usize) -> Option<u32> {
    Some(u32::from_be_bytes(
        data.get(offset..offset + 4)?.try_into().ok()?,
    ))
}

/// Reads the pixel dimensions of a video, or `None` if the bytes aren't a video
/// container we understand.
pub fn video_dimensions(bytes: &[u8]) -> Option<(u32, u32)> {
    match iso_dimensions(bytes) {
        Some(dimensions) => Some(dimensions),
        None => matroska_dimensions(bytes),
    }
}

// -- MP4 / QuickTime ---------------------------------------------------------

/// Splits a run of ISO base media file format boxes into their type and their
/// payload (the box contents with the size/type header removed).
///
/// Parsing stops at the first malformed box rather than failing outright, since
/// a truncated box at the end of a file still leaves the earlier boxes usable.
fn iso_boxes(data: &[u8]) -> Vec<([u8; 4], &[u8])> {
    let mut boxes: Vec<([u8; 4], &[u8])> = Vec::new();
    let mut offset: usize = 0;

    while offset + 8 <= data.len() {
        let box_type: [u8; 4] = match data.get(offset + 4..offset + 8) {
            Some(slice) => match slice.try_into() {
                Ok(box_type2) => box_type2,
                Err(_) => break,
            },
            None => break,
        };

        let (header_size, box_size): (usize, usize) = match read_u32(data, offset) {
            // A size of 1 means the real size is a 64 bit value following the type.
            Some(1) => match data.get(offset + 8..offset + 16) {
                Some(slice) => match slice.try_into().map(u64::from_be_bytes) {
                    Ok(large_size) => match usize::try_from(large_size) {
                        Ok(large_size2) => (16, large_size2),
                        Err(_) => break,
                    },
                    Err(_) => break,
                },
                None => break,
            },
            // A size of 0 means the box runs to the end of the file.
            Some(0) => (8, data.len() - offset),
            Some(size) => (8, size as usize),
            None => break,
        };

        if box_size < header_size {
            break;
        }

        let end: usize = match offset.checked_add(box_size) {
            Some(end2) if end2 <= data.len() => end2,
            _ => break,
        };

        match data.get(offset + header_size..end) {
            Some(payload) => boxes.push((box_type, payload)),
            None => break,
        }

        offset = end;
    }

    boxes
}

fn find_iso_box<'a>(boxes: &[([u8; 4], &'a [u8])], box_type: &[u8; 4]) -> Option<&'a [u8]> {
    boxes
        .iter()
        .find(|(box_type2, _)| box_type2 == box_type)
        .map(|(_, payload)| *payload)
}

/// Converts a 16.16 fixed point number to the nearest whole number.
fn from_fixed_point(value: u32) -> u32 {
    value.saturating_add(0x8000) >> 16
}

/// Reads the display dimensions out of a track header box.
///
/// The header also carries the transformation matrix the track is displayed
/// with. Phone cameras record in landscape and store a rotation in that matrix,
/// so a portrait video has landscape dimensions here that only come out the
/// right way around once the rotation is applied.
fn track_header_dimensions(payload: &[u8]) -> Option<(u32, u32)> {
    let version: u8 = *payload.first()?;

    // version and flags, then creation time, modification time, track id,
    // reserved and duration. The times and the duration are 64 bit in version 1.
    let after_times: usize = if version == 1 { 36 } else { 24 };

    // reserved, layer, alternate group, volume and more reserved.
    let matrix_offset: usize = after_times + 16;

    // The matrix is {a, b, u, c, d, v, x, y, w}, where a and d scale and b and c
    // rotate. A quarter turn zeroes the scale entries and fills in the rotation
    // entries, which is exactly when the width and height are swapped on screen.
    let a: u32 = read_u32(payload, matrix_offset)?;
    let b: u32 = read_u32(payload, matrix_offset + 4)?;
    let c: u32 = read_u32(payload, matrix_offset + 12)?;
    let d: u32 = read_u32(payload, matrix_offset + 16)?;
    let is_quarter_turn: bool = a == 0 && d == 0 && b != 0 && c != 0;

    let width = from_fixed_point(read_u32(payload, matrix_offset + 36)?);
    let height = from_fixed_point(read_u32(payload, matrix_offset + 40)?);

    if is_quarter_turn {
        Some((height, width))
    } else {
        Some((width, height))
    }
}

/// Reads the coded dimensions out of a sample description box.
///
/// This is the size the frames were encoded at rather than the size they are
/// displayed at, and is only used when the track header has nothing usable.
fn sample_description_dimensions(payload: &[u8]) -> Option<(u32, u32)> {
    // version, flags and the entry count, followed by the sample entries.
    let entries: &[u8] = payload.get(8..)?;

    iso_boxes(entries).into_iter().find_map(|(_, entry)| {
        // A visual sample entry starts with reserved bytes, a data reference
        // index and predefined/reserved fields before the dimensions.
        let width: u32 = u32::from(read_u16(entry, 24)?);
        let height: u32 = u32::from(read_u16(entry, 26)?);

        if width > 0 && height > 0 {
            Some((width, height))
        } else {
            None
        }
    })
}

fn iso_dimensions(bytes: &[u8]) -> Option<(u32, u32)> {
    let movie: &[u8] = find_iso_box(&iso_boxes(bytes), b"moov")?;

    iso_boxes(movie)
        .into_iter()
        .filter(|(box_type, _)| box_type == b"trak")
        .find_map(|(_, track)| {
            let track_children: Vec<([u8; 4], &[u8])> = iso_boxes(track);
            let media_children: Vec<([u8; 4], &[u8])> =
                iso_boxes(find_iso_box(&track_children, b"mdia")?);

            // Tracks holding audio, subtitles or timed metadata are laid out the
            // same way, so the handler is what tells us this is the picture.
            let is_video: bool = find_iso_box(&media_children, b"hdlr")
                .and_then(|handler| handler.get(8..12))
                .is_some_and(|handler_type| handler_type == b"vide");

            if !is_video {
                return None;
            }

            let header_dimensions: Option<(u32, u32)> =
                find_iso_box(&track_children, b"tkhd").and_then(track_header_dimensions);

            match header_dimensions {
                Some((width, height)) if width > 0 && height > 0 => Some((width, height)),
                _ => {
                    let information: &[u8] = find_iso_box(&media_children, b"minf")?;
                    let table: &[u8] = find_iso_box(&iso_boxes(information), b"stbl")?;
                    sample_description_dimensions(find_iso_box(&iso_boxes(table), b"stsd")?)
                }
            }
        })
}

// -- WebM / Matroska ---------------------------------------------------------

const EBML_HEADER: [u8; 4] = [0x1A, 0x45, 0xDF, 0xA3];
const SEGMENT_ID: u64 = 0x1853_8067;
const TRACKS_ID: u64 = 0x1654_AE6B;
const TRACK_ENTRY_ID: u64 = 0xAE;
const VIDEO_ID: u64 = 0xE0;
const PIXEL_WIDTH_ID: u64 = 0xB0;
const PIXEL_HEIGHT_ID: u64 = 0xBA;
const DISPLAY_WIDTH_ID: u64 = 0x54B0;
const DISPLAY_HEIGHT_ID: u64 = 0x54BA;
const DISPLAY_UNIT_ID: u64 = 0x54B2;

/// Reads a variable length integer, returning it along with how many bytes it
/// took up.
///
/// The leading zeroes of the first byte say how long the number is. Element ids
/// are compared as written including that length marker, while lengths have the
/// marker stripped off to get their value, which is what `keep_marker` selects.
fn read_variable_int(data: &[u8], offset: usize, keep_marker: bool) -> Option<(u64, usize)> {
    let first: u8 = *data.get(offset)?;

    if first == 0 {
        return None;
    }

    let length: usize = first.leading_zeros() as usize + 1;

    // The eight byte form has its marker in the last bit of the first byte, so
    // stripping the marker off leaves nothing of that byte behind.
    let mut value: u64 = if keep_marker {
        u64::from(first)
    } else {
        u64::from(first) & (0xFF >> length)
    };

    for index in 1..length {
        value = (value << 8) | u64::from(*data.get(offset + index)?);
    }

    Some((value, length))
}

/// Splits an EBML element's contents into the ids and payloads of its children.
fn ebml_children(data: &[u8]) -> Vec<(u64, &[u8])> {
    let mut children: Vec<(u64, &[u8])> = Vec::new();
    let mut offset: usize = 0;

    while offset < data.len() {
        let (id, id_length) = match read_variable_int(data, offset, true) {
            Some(id2) => id2,
            None => break,
        };
        let (size, size_length) = match read_variable_int(data, offset + id_length, false) {
            Some(size2) => size2,
            None => break,
        };

        let start: usize = offset + id_length + size_length;

        // An element with every size bit set runs until something ends it. The
        // segment is written that way when the file is produced as a stream, and
        // it is the last element in the file, so the rest of the file is its
        // contents and there is nothing after it to look at.
        let is_unknown_size: bool = size == (1u64 << (7 * size_length)) - 1;

        let end: usize = if is_unknown_size {
            data.len()
        } else {
            match usize::try_from(size).ok().and_then(|size2| {
                let end2 = start.checked_add(size2)?;
                (end2 <= data.len()).then_some(end2)
            }) {
                Some(end2) => end2,
                None => break,
            }
        };

        match data.get(start..end) {
            Some(payload) => children.push((id, payload)),
            None => break,
        }

        if is_unknown_size {
            break;
        }

        offset = end;
    }

    children
}

fn find_ebml_child<'a>(children: &[(u64, &'a [u8])], id: u64) -> Option<&'a [u8]> {
    children
        .iter()
        .find(|(id2, _)| *id2 == id)
        .map(|(_, payload)| *payload)
}

/// Reads an EBML unsigned integer, which is stored big endian with any leading
/// zero bytes left off.
fn find_ebml_uint(children: &[(u64, &[u8])], id: u64) -> Option<u64> {
    let payload: &[u8] = find_ebml_child(children, id)?;

    if payload.is_empty() || payload.len() > 8 {
        return None;
    }

    let mut value: u64 = 0;

    for byte in payload {
        value = (value << 8) | u64::from(*byte);
    }

    Some(value)
}

fn matroska_dimensions(bytes: &[u8]) -> Option<(u32, u32)> {
    if bytes.get(0..4)? != EBML_HEADER {
        return None;
    }

    let segment: &[u8] = find_ebml_child(&ebml_children(bytes), SEGMENT_ID)?;
    let tracks: &[u8] = find_ebml_child(&ebml_children(segment), TRACKS_ID)?;

    ebml_children(tracks)
        .into_iter()
        .filter(|(id, _)| *id == TRACK_ENTRY_ID)
        .find_map(|(_, track_entry)| {
            let video: &[u8] = find_ebml_child(&ebml_children(track_entry), VIDEO_ID)?;
            let children: Vec<(u64, &[u8])> = ebml_children(video);

            // The display size is what the video should be shown at, which is
            // what a stretched or anamorphic video needs. It is optional, and
            // only in pixels when the display unit says so.
            let display_size: Option<(u32, u32)> = match find_ebml_uint(&children, DISPLAY_UNIT_ID)
            {
                Some(0) | None => match (
                    find_ebml_uint(&children, DISPLAY_WIDTH_ID),
                    find_ebml_uint(&children, DISPLAY_HEIGHT_ID),
                ) {
                    (Some(width), Some(height)) => Some((width as u32, height as u32)),
                    _ => None,
                },
                Some(_) => None,
            };

            let size: (u32, u32) = match display_size {
                Some(display_size2) => display_size2,
                None => (
                    find_ebml_uint(&children, PIXEL_WIDTH_ID)? as u32,
                    find_ebml_uint(&children, PIXEL_HEIGHT_ID)? as u32,
                ),
            };

            let (width, height) = size;

            if width > 0 && height > 0 {
                Some((width, height))
            } else {
                None
            }
        })
}

#[cfg(test)]
mod tests {
    use super::video_dimensions;

    fn iso_box(box_type: &[u8; 4], payload: &[u8]) -> Vec<u8> {
        let mut bytes: Vec<u8> = ((payload.len() as u32) + 8).to_be_bytes().to_vec();
        bytes.extend_from_slice(box_type);
        bytes.extend_from_slice(payload);
        bytes
    }

    const IDENTITY_MATRIX: [u32; 9] = [0x0001_0000, 0, 0, 0, 0x0001_0000, 0, 0, 0, 0x4000_0000];

    /// A quarter turn clockwise, which is how a phone records a portrait video.
    const ROTATED_MATRIX: [u32; 9] = [0, 0x0001_0000, 0, 0xFFFF_0000, 0, 0, 0, 0, 0x4000_0000];

    fn track_header(matrix: [u32; 9], width: u32, height: u32) -> Vec<u8> {
        let mut payload: Vec<u8> = vec![0; 24 + 16];

        for value in matrix {
            payload.extend_from_slice(&value.to_be_bytes());
        }

        payload.extend_from_slice(&(width << 16).to_be_bytes());
        payload.extend_from_slice(&(height << 16).to_be_bytes());
        iso_box(b"tkhd", &payload)
    }

    fn handler(handler_type: &[u8; 4]) -> Vec<u8> {
        let mut payload: Vec<u8> = vec![0; 8];
        payload.extend_from_slice(handler_type);
        payload.extend_from_slice(&[0; 12]);
        iso_box(b"hdlr", &payload)
    }

    fn sample_description(width: u16, height: u16) -> Vec<u8> {
        let mut entry: Vec<u8> = vec![0; 24];
        entry.extend_from_slice(&width.to_be_bytes());
        entry.extend_from_slice(&height.to_be_bytes());

        let mut payload: Vec<u8> = vec![0; 8];
        payload.extend_from_slice(&iso_box(b"avc1", &entry));
        iso_box(b"stsd", &payload)
    }

    /// Builds an `MP4` file holding a single track.
    fn mp4(
        track_header_box: &[u8],
        handler_type: &[u8; 4],
        sample_entry: Option<Vec<u8>>,
    ) -> Vec<u8> {
        let mut media: Vec<u8> = handler(handler_type);

        if let Some(sample_entry2) = sample_entry {
            media.extend_from_slice(&iso_box(b"minf", &iso_box(b"stbl", &sample_entry2)));
        }

        let mut track: Vec<u8> = track_header_box.to_vec();
        track.extend_from_slice(&iso_box(b"mdia", &media));

        let mut bytes: Vec<u8> = iso_box(b"ftyp", b"isom\0\0\x02\0isomiso2avc1mp41");
        bytes.extend_from_slice(&iso_box(b"moov", &iso_box(b"trak", &track)));
        bytes
    }

    #[test]
    fn reads_mp4_dimensions_from_the_track_header() {
        assert_eq!(
            video_dimensions(&mp4(
                &track_header(IDENTITY_MATRIX, 1920, 1080),
                b"vide",
                None
            )),
            Some((1920, 1080)),
            "the track header dimensions should be used as they are"
        );
    }

    #[test]
    fn applies_mp4_rotation_to_the_dimensions() {
        assert_eq!(
            video_dimensions(&mp4(
                &track_header(ROTATED_MATRIX, 1920, 1080),
                b"vide",
                None
            )),
            Some((1080, 1920)),
            "a quarter turn should swap the width and the height"
        );
    }

    #[test]
    fn falls_back_to_the_mp4_sample_description() {
        assert_eq!(
            video_dimensions(&mp4(
                &track_header(IDENTITY_MATRIX, 0, 0),
                b"vide",
                Some(sample_description(640, 480))
            )),
            Some((640, 480)),
            "an empty track header should fall back to the coded dimensions"
        );
    }

    #[test]
    fn ignores_mp4_tracks_that_are_not_video() {
        assert_eq!(
            video_dimensions(&mp4(
                &track_header(IDENTITY_MATRIX, 1920, 1080),
                b"soun",
                None
            )),
            None,
            "an audio track has no dimensions to report, however its header reads"
        );
    }

    fn ebml_element(id: &[u8], payload: &[u8]) -> Vec<u8> {
        let mut bytes: Vec<u8> = id.to_vec();
        // The longest form of a length is a leading 0x01 followed by 7 bytes.
        bytes.push(0x01);
        bytes.extend_from_slice(&(payload.len() as u64).to_be_bytes()[1..8]);
        bytes.extend_from_slice(payload);
        bytes
    }

    fn ebml_uint(id: &[u8], value: u16) -> Vec<u8> {
        ebml_element(id, &value.to_be_bytes())
    }

    /// Builds a `WebM` file holding a single video track.
    fn webm(video: &[u8]) -> Vec<u8> {
        let mut bytes: Vec<u8> = ebml_element(&[0x1A, 0x45, 0xDF, 0xA3], &[]);
        bytes.extend_from_slice(&ebml_element(
            &[0x18, 0x53, 0x80, 0x67],
            &ebml_element(
                &[0x16, 0x54, 0xAE, 0x6B],
                &ebml_element(&[0xAE], &ebml_element(&[0xE0], video)),
            ),
        ));
        bytes
    }

    #[test]
    fn reads_webm_pixel_dimensions() {
        let mut video: Vec<u8> = ebml_uint(&[0xB0], 1280);
        video.extend_from_slice(&ebml_uint(&[0xBA], 720));

        assert_eq!(
            video_dimensions(&webm(&video)),
            Some((1280, 720)),
            "the pixel dimensions should be read from the video track"
        );
    }

    #[test]
    fn prefers_webm_display_dimensions() {
        let mut video: Vec<u8> = ebml_uint(&[0xB0], 720);
        video.extend_from_slice(&ebml_uint(&[0xBA], 480));
        video.extend_from_slice(&ebml_uint(&[0x54, 0xB0], 640));
        video.extend_from_slice(&ebml_uint(&[0x54, 0xBA], 480));

        assert_eq!(
            video_dimensions(&webm(&video)),
            Some((640, 480)),
            "an anamorphic video should report the size it is displayed at"
        );
    }

    #[test]
    fn ignores_webm_display_dimensions_that_are_not_pixels() {
        let mut video: Vec<u8> = ebml_uint(&[0xB0], 720);
        video.extend_from_slice(&ebml_uint(&[0xBA], 480));
        video.extend_from_slice(&ebml_uint(&[0x54, 0xB0], 4));
        video.extend_from_slice(&ebml_uint(&[0x54, 0xBA], 3));
        // A display unit of 3 means the display size is an aspect ratio.
        video.extend_from_slice(&ebml_uint(&[0x54, 0xB2], 3));

        assert_eq!(
            video_dimensions(&webm(&video)),
            Some((720, 480)),
            "an aspect ratio is not a size, so the pixel dimensions should be used"
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
}
