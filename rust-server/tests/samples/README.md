# Video test samples

Container headers used by the tests in `src/video.rs`. Each one has had its
picture data removed, so what is left is the box/element structure and the
sample tables — the part `video_metadata` actually reads. That keeps them small
enough to sit in the repository.

Both video samples run ten seconds at thirty frames a second, and both have had
a creation time of 2024-03-15T12:30:45Z written into them. The two containers
count time from different years, so agreeing on that one instant is what the
date tests are checking.

| File | Reports | Built from |
| --- | --- | --- |
| `landscape.mp4` | 640x360, h.264 | `ftyp` + `moov` of [Big Buck Bunny 360p](https://test-videos.co.uk/bigbuckbunny/mp4-h264), `mdat` dropped, creation time set. Big Buck Bunny is (c) Blender Foundation, CC-BY 3.0 |
| `rotated.mp4` | 360x640, 90 degrees | `landscape.mp4` with a quarter turn written into the `tkhd` matrix, which is how a phone stores a portrait recording |
| `landscape.webm` | 640x360, `VP9` | `EBML` header, `Info` and `Tracks` of [Jellyfish 360p](https://test-videos.co.uk/jellyfish), plus a minimal empty cluster and a `DateUTC` |
| `anamorphic.webm` | 480x360 | `landscape.webm` with a display size written into its video track, so the size it is shown at differs from the 640x360 it is coded at |
| `audio_only.mp4` | nothing | `ftyp` + `moov` of an `AAC` sample, `mdat` dropped. Has no video track, so it must report nothing at all |
