# Video test samples

Container headers used by the tests in `src/video.rs`. Each one has had its
picture data removed, so what is left is the box/element structure and the
sample tables — the part `video_dimensions` actually reads. That keeps them
small enough to sit in the repository.

| File | Reports | Built from |
| --- | --- | --- |
| `landscape.mp4` | 640x360 | `ftyp` + `moov` of [Big Buck Bunny 360p](https://test-videos.co.uk/bigbuckbunny/mp4-h264), `mdat` dropped. Big Buck Bunny is (c) Blender Foundation, CC-BY 3.0 |
| `rotated.mp4` | 360x640 | `landscape.mp4` with a quarter turn written into the `tkhd` matrix, which is how a phone stores a portrait recording |
| `landscape.webm` | 640x360 | `EBML` header, `Info` and `Tracks` of [Jellyfish 360p](https://test-videos.co.uk/jellyfish), plus a minimal empty cluster |
| `anamorphic.webm` | 480x360 | `landscape.webm` with a display size written into its video track, so the size it is shown at differs from the 640x360 it is coded at |
| `audio_only.mp4` | nothing | `ftyp` + `moov` of an `AAC` sample, `mdat` dropped. Has no video track, so it must report no dimensions |
