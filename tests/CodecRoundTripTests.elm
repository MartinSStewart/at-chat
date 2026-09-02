module CodecRoundTripTests exposing (tests)

import Coord
import Effect.Time as Time
import Expect
import FileName
import FileStatus
import Quantity
import Serialize
import Test exposing (Test, describe, test)


tests : Test
tests =
    describe "Codec round trips"
        [ test "A file name survives being encoded and read back" <|
            \_ ->
                FileName.fromString "holiday photo.jpeg"
                    |> roundTrip FileName.codec
        , test "A file name that had to be cleaned up survives too" <|
            \_ ->
                FileName.fromString "  /nested\\name\nwith newlines  "
                    |> roundTrip FileName.codec
        , test "A file with no metadata survives" <|
            \_ ->
                { fileName = FileName.fromString "notes.txt"
                , fileSize = 0
                , metadata = Nothing
                , contentType = FileStatus.contentType "text/plain"
                , fileHash = FileStatus.fileHash "abc123"
                , isEncrypted = FileStatus.IsNotEncrypted
                }
                    |> roundTrip FileStatus.fileDataSerializeCodec
        , test "An image with every piece of metadata filled in survives" <|
            \_ ->
                { fileName = FileName.fromString "photo.jpg"
                , fileSize = 4294967295
                , metadata =
                    Just
                        (FileStatus.FileMetadata_Image
                            { imageSize = Coord.xy 4032 3024
                            , orientation = Just FileStatus.MirroredRotation270
                            , gpsLocation = Just { lat = -33.8688, lon = 151.2093 }
                            , cameraOwner = Just "someone"
                            , exposureTime = Just { numerator = 1, denominator = 250 }
                            , fNumber = Just 1.8
                            , focalLength = Just 26.5
                            , isoSpeedRating = Just 400
                            , make = Just "Make"
                            , model = Just "Model"
                            , software = Just "Software"
                            , userComment = Just "A comment"
                            }
                        )
                , contentType = FileStatus.contentType "image/jpeg"
                , fileHash = FileStatus.fileHash "0123456789abcdef"
                , isEncrypted = FileStatus.IsNotEncrypted
                }
                    |> roundTrip FileStatus.fileDataSerializeCodec
        , test "A video with every piece of metadata filled in survives" <|
            \_ ->
                { fileName = FileName.fromString "clip.mp4"
                , fileSize = 100000000
                , metadata =
                    Just
                        (FileStatus.FileMetadata_Video
                            { videoSize = Coord.xy 1920 1080
                            , frames = Just (Quantity.Quantity 3600)
                            , createdAt = Just (Time.millisToPosix 1234567890)
                            , orientation = FileStatus.Rotation90
                            , frameRate = Just (Quantity.Quantity 29.97)
                            , codec = Just "avc1.640028"
                            , title = Just "A title"
                            , gpsLocation = Just { lat = 0, lon = 0 }
                            }
                        )
                , contentType = FileStatus.contentType "video/mp4"
                , fileHash = FileStatus.fileHash "fedcba9876543210"
                , isEncrypted = FileStatus.IsNotEncrypted
                }
                    |> roundTrip FileStatus.fileDataSerializeCodec
        ]


roundTrip : Serialize.Codec e a -> a -> Expect.Expectation
roundTrip codec value =
    Serialize.encodeToBytes codec value
        |> Serialize.decodeFromBytes codec
        |> Expect.equal (Ok value)
