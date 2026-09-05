module CodecRoundTripTests exposing (tests)

import Array
import Bytes
import Bytes.Decode
import Bytes.Encode
import Coord
import Duration
import Effect.Time as Time
import Encryption
import Expect
import FileName
import FileStatus
import Id
import List.Nonempty
import Message
import Quantity
import RichText
import SeqDict
import Serialize
import Test exposing (Test, describe, test)


tests : Test
tests =
    describe "Codecs" [ roundTripTests, portWireFormatTests ]


{-| The bytes elm-pkg-js/stuff.js writes by hand for a file it has encrypted. Pinning them
on both sides is what stops the two drifting: tests/EncryptionPortTests.js checks that the
handwritten writer produces exactly these, and these check that Elm still reads them.
-}
portWireFormatTests : Test
portWireFormatTests =
    let
        -- Request id 7, a one byte key of 170 and one byte of ciphertext of 187.
        fileEncrypted : Maybe Bytes.Bytes -> Maybe FileStatus.MeasuredFile -> Encryption.FromJs ()
        fileEncrypted thumbnail measured =
            Encryption.FromJs_FileEncrypted
                (Id.fromInt 7)
                { key = byteList [ 170 ]
                , data = byteList [ 187 ]
                , thumbnail = thumbnail
                , measured = measured
                }
    in
    describe "The bytes the encryption port passes"
        [ test "A file nothing could be measured about" <|
            \_ ->
                fileEncrypted Nothing Nothing
                    |> hasBytes [ 1, 0, 9, 64, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 170, 0, 0, 0, 1, 187, 0, 0, 0, 0 ]
        , test "An image too small to have wanted a thumbnail" <|
            \_ ->
                FileStatus.MeasuredImage (Coord.xy 640 480)
                    |> Just
                    |> fileEncrypted Nothing
                    |> hasBytes
                        [ 1, 0, 9, 64, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 170, 0, 0, 0, 1, 187, 0, 0, 0, 1, 0, 0, 0, 0, 64, 132, 0, 0, 0, 0, 0, 0, 0, 0, 64, 126, 0, 0, 0, 0, 0, 0 ]
        , test "An image the browser made a thumbnail of" <|
            \_ ->
                FileStatus.MeasuredImage (Coord.xy 640 480)
                    |> Just
                    |> fileEncrypted (Just (byteList [ 1, 2, 3 ]))
                    |> hasBytes
                        [ 1, 0, 9, 64, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 170, 0, 0, 0, 1, 187, 0, 1, 0, 0, 0, 3, 1, 2, 3, 0, 1, 0, 0, 0, 0, 64, 132, 0, 0, 0, 0, 0, 0, 0, 0, 64, 126, 0, 0, 0, 0, 0, 0 ]
        , test "A video whose length the container didn't say" <|
            \_ ->
                FileStatus.MeasuredVideo (Coord.xy 1920 1080) Nothing
                    |> Just
                    |> fileEncrypted Nothing
                    |> hasBytes
                        [ 1, 0, 9, 64, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 170, 0, 0, 0, 1, 187, 0, 0, 0, 1, 0, 1, 0, 0, 64, 158, 0, 0, 0, 0, 0, 0, 0, 0, 64, 144, 224, 0, 0, 0, 0, 0, 0, 0 ]
        , test "A video that was measured" <|
            \_ ->
                FileStatus.MeasuredVideo (Coord.xy 1920 1080) (Just (Duration.seconds 2.5))
                    |> Just
                    |> fileEncrypted Nothing
                    |> hasBytes
                        [ 1, 0, 9, 64, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 170, 0, 0, 0, 1, 187, 0, 0, 0, 1, 0, 1, 0, 0, 64, 158, 0, 0, 0, 0, 0, 0, 0, 0, 64, 144, 224, 0, 0, 0, 0, 0, 0, 1, 64, 163, 136, 0, 0, 0, 0, 0 ]
        , -- A message encrypted on its own travels as a field of the request, so the browser
          -- is handed exactly the bytes that come back as a field of the answer. One
          -- encrypted as part of a batch has to be written the same way, or what gets stored
          -- can't be read back afterwards.
          test "A batch frames a message the way encrypting one on its own does" <|
            \_ ->
                Encryption.ToJs_EncryptNewMessage
                    { requestId = Id.fromInt 7, otherUserId = Id.fromInt 3, data = shortMessage }
                    |> Serialize.encodeToBytes (Encryption.toJsCodec Message.contentAndEmbedsCodec)
                    |> toByteList
                    -- The version, the variant tag and the two ids, which stuff.js reads the
                    -- message out from behind.
                    |> List.drop 19
                    |> Expect.equal
                        (Encryption.messageBytes Message.contentAndEmbedsCodec shortMessage
                            |> toByteList
                        )
        , -- The round trip a batch makes: these are the bytes stuff.js reads the messages
          -- out of, and the ones it writes back once they are decrypted.
          -- tests/EncryptionPortTests.js runs the first through it and checks it produces
          -- the second, which is what catches the two being framed differently.
          test "A batch of messages handed over to be encrypted" <|
            \_ ->
                Encryption.ToJs_EncryptManyMessages
                    { requestId = Id.fromInt 7
                    , otherUserId = Id.fromInt 3
                    , data =
                        [ Encryption.messageBytes Message.contentAndEmbedsCodec shortMessage ]
                    }
                    |> Serialize.encodeToBytes (Encryption.toJsCodec Serialize.unit)
                    |> toByteList
                    |> Expect.equal batchRequestBytes
        , test "A batch of messages handed back decrypted" <|
            \_ ->
                Encryption.FromJs_ManyMessagesDecrypted (Id.fromInt 7) [ Ok shortMessage ]
                    |> Serialize.encodeToBytes (Encryption.fromJsCodec Message.contentAndEmbedsCodec)
                    |> toByteList
                    |> Expect.equal batchAnswerBytes
        , -- The request stuff.js reads the file and its type back out of.
          test "A file handed over to be encrypted" <|
            \_ ->
                Encryption.ToJs_EncryptFile
                    { requestId = Id.fromInt 7
                    , contentType = "image/png"
                    , data = byteList [ 1, 2, 3 ]
                    }
                    |> Serialize.encodeToBytes (Encryption.toJsCodec Serialize.unit)
                    |> toByteList
                    |> Expect.equal
                        [ 1, 0, 5, 64, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 105, 109, 97, 103, 101, 47, 112, 110, 103, 0, 0, 0, 3, 1, 2, 3 ]
        ]


hasBytes : List Int -> Encryption.FromJs () -> Expect.Expectation
hasBytes expected fromJs =
    Serialize.encodeToBytes (Encryption.fromJsCodec Serialize.unit) fromJs
        |> toByteList
        |> Expect.equal expected


{-| Request id 7, conversation with user 3, one message reading "hi".
-}
batchRequestBytes : List Int
batchRequestBytes =
    [ 1, 0, 4, 64, 28, 0, 0, 0, 0, 0, 0, 64, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 25, 0, 0, 0, 1, 0, 0, 0, 104, 0, 0, 0, 1, 105, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]


batchAnswerBytes : List Int
batchAnswerBytes =
    [ 1, 0, 6, 64, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 104, 0, 0, 0, 1, 105, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]


shortMessage : Message.MessageContent (Id.Id Id.UserId)
shortMessage =
    { content = List.Nonempty.Nonempty (RichText.NormalText 'h' "i") []
    , embeds = Array.empty
    , attachedFiles = SeqDict.empty
    }


byteList : List Int -> Bytes.Bytes
byteList bytes =
    List.map Bytes.Encode.unsignedInt8 bytes
        |> Bytes.Encode.sequence
        |> Bytes.Encode.encode


toByteList : Bytes.Bytes -> List Int
toByteList bytes =
    Bytes.Decode.decode
        (Bytes.Decode.loop ( Bytes.width bytes, [] )
            (\( left, soFar ) ->
                if left <= 0 then
                    Bytes.Decode.succeed (Bytes.Decode.Done (List.reverse soFar))

                else
                    Bytes.Decode.map
                        (\byte -> Bytes.Decode.Loop ( left - 1, byte :: soFar ))
                        Bytes.Decode.unsignedInt8
            )
        )
        bytes
        |> Maybe.withDefault []


roundTripTests : Test
roundTripTests =
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
        , -- The key and whether a thumbnail was made travel inside the encrypted message,
          -- so they have to survive the codec that puts them there.
          test "An encrypted file with a thumbnail survives" <|
            \_ ->
                { fileName = FileName.fromString "photo.png"
                , fileSize = 2048
                , metadata = Nothing
                , contentType = FileStatus.contentType "image/png"
                , fileHash = FileStatus.fileHash "abc123"
                , isEncrypted =
                    FileStatus.IsEncrypted
                        (byteList (List.range 0 31) |> FileStatus.aesPrivateKey)
                        FileStatus.HasEncryptedThumbnail
                }
                    |> roundTrip FileStatus.fileDataSerializeCodec
        , test "An encrypted file the browser made no thumbnail of survives" <|
            \_ ->
                { fileName = FileName.fromString "photo.png"
                , fileSize = 2048
                , metadata = Nothing
                , contentType = FileStatus.contentType "image/png"
                , fileHash = FileStatus.fileHash "abc123"
                , isEncrypted =
                    FileStatus.IsEncrypted
                        (byteList (List.range 0 31) |> FileStatus.aesPrivateKey)
                        FileStatus.NoEncryptedThumbnail
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
                            , duration = Just (Duration.seconds 12.5)
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
