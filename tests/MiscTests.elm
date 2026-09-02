module MiscTests exposing (tests)

import Backend
import Bytes.Encode
import Coord
import CssPixels exposing (CssPixels)
import DiscordSync
import Effect.Time as Time
import Emoji exposing (EmojiOrCustomEmoji(..))
import Expect
import FileName
import FileStatus
import Id exposing (CustomEmojiId, Id)
import Pages.Guild exposing (HighlightMessage(..), IsHovered(..))
import SeqSet
import String.Nonempty
import Test exposing (Test)
import User
import UserAgent
import X25519


{-| The server reads more out of a file than the browser can, so what the browser measured
before uploading only stands in for a file the server couldn't read.
-}
uploadedFileMetadataTests : Test
uploadedFileMetadataTests =
    let
        measured : FileStatus.FileMetadata
        measured =
            FileStatus.measuredFileMetadata (FileStatus.MeasuredImage (Coord.xy 128 96))

        uploading : FileStatus.FileStatus
        uploading =
            FileStatus.FileUploading
                (FileName.fromString "photo.png")
                { sent = 0, size = 10 }
                (FileStatus.contentType "image/png")
                FileStatus.IsNotEncrypted

        uploaded : Maybe FileStatus.FileMetadata -> Maybe (Coord.Coord CssPixels) -> Maybe FileStatus.FileMetadata
        uploaded clientMetadata serverImageSize =
            case
                FileStatus.addFileHash
                    clientMetadata
                    (Ok
                        { fileHash = FileStatus.fileHash "abc123"
                        , videoMetadata = Nothing
                        , imageMetadata = Maybe.map imageMetadata serverImageSize
                        }
                    )
                    uploading
            of
                FileStatus.FileUploaded fileData ->
                    fileData.metadata

                _ ->
                    Nothing

        imageSizeOf : Maybe FileStatus.FileMetadata -> Maybe (Coord.Coord CssPixels)
        imageSizeOf metadata =
            case metadata of
                Just (FileStatus.FileMetadata_Image image) ->
                    Just image.imageSize

                _ ->
                    Nothing
    in
    Test.describe "What an uploaded file ends up saying about itself"
        [ Test.test "The server's answer wins when it could read the file" <|
            \_ ->
                uploaded (Just measured) (Just (Coord.xy 640 480))
                    |> imageSizeOf
                    |> Expect.equal (Just (Coord.xy 640 480))
        , Test.test "What the browser measured stands in when the server couldn't read it" <|
            \_ ->
                uploaded (Just measured) Nothing
                    |> imageSizeOf
                    |> Expect.equal (Just (Coord.xy 128 96))
        , Test.test "Neither one leaves the file saying nothing about itself" <|
            \_ ->
                uploaded Nothing Nothing
                    |> Expect.equal Nothing
        ]


imageMetadata : Coord.Coord CssPixels -> FileStatus.ImageMetadata
imageMetadata imageSize =
    { imageSize = imageSize
    , orientation = Nothing
    , gpsLocation = Nothing
    , cameraOwner = Nothing
    , exposureTime = Nothing
    , fNumber = Nothing
    , focalLength = Nothing
    , isoSpeedRating = Nothing
    , make = Nothing
    , model = Nothing
    , software = Nothing
    , userComment = Nothing
    }


attachmentUrlTests : Test
attachmentUrlTests =
    let
        plainFile : FileStatus.FileData
        plainFile =
            { fileName = FileName.fromString "photo.png"
            , fileSize = 1234
            , metadata = Nothing
            , contentType = FileStatus.contentType "image/png"
            , fileHash = FileStatus.fileHash "abc123"
            , isEncrypted = FileStatus.IsNotEncrypted
            }

        encryptedFile : FileStatus.FileData
        encryptedFile =
            { plainFile
                | isEncrypted =
                    List.range 0 31
                        |> List.map Bytes.Encode.unsignedInt8
                        |> Bytes.Encode.sequence
                        |> Bytes.Encode.encode
                        |> FileStatus.aesPrivateKey
                        |> FileStatus.IsEncrypted
            }

        -- Big enough that the server would have made a thumbnail for it.
        largeImage : Coord.Coord CssPixels
        largeImage =
            Coord.xy 4000 4000
    in
    Test.describe "Where an attached file is read back from"
        [ Test.test "An unencrypted file is fetched straight from the server" <|
            \_ ->
                FileStatus.fileDataUrl plainFile
                    |> String.endsWith "/file/2/abc123"
                    |> Expect.equal True
        , Test.test "An encrypted file goes through the service worker instead" <|
            \_ ->
                FileStatus.fileDataUrl encryptedFile
                    |> String.endsWith "/file/e/2/abc123"
                    |> Expect.equal True
        , Test.test "A large unencrypted image is shown as the server's thumbnail" <|
            \_ ->
                FileStatus.fileDataThumbnailUrl largeImage plainFile
                    |> String.endsWith "/file/t/abc123"
                    |> Expect.equal True
        , -- The server can't decode ciphertext, so there is no thumbnail to ask it for.
          Test.test "A large encrypted image has no thumbnail to fall back on" <|
            \_ ->
                FileStatus.fileDataThumbnailUrl largeImage encryptedFile
                    |> String.endsWith "/file/e/2/abc123"
                    |> Expect.equal True
        ]


tests : Test
tests =
    Test.describe
        "Misc tests"
        [ redactPrivateKeysTests
        , attachmentUrlTests
        , uploadedFileMetadataTests
        , Test.test "Round trip message view encoding" <|
            \_ ->
                let
                    input =
                        { isMobile = False
                        , containerWidth = 400
                        , isEditing = True
                        , highlight = MentionHighlight
                        , isHovered = IsHovered
                        , time = Time.millisToPosix 1786013400000
                        }
                in
                Pages.Guild.encodeMessageView input.isMobile input.isHovered input.containerWidth input.isEditing input.highlight input.time
                    |> Pages.Guild.decodeMessageView
                    |> Expect.equal input
        , Test.test "Round trip message view encoding 2" <|
            \_ ->
                let
                    input =
                        { isMobile = True
                        , containerWidth = 2000
                        , isEditing = False
                        , highlight = NoHighlight
                        , isHovered = IsHoveredButNoMenu
                        , -- Only whole minutes survive the round trip, which is all the
                          -- timestamps in a message need
                          time = Time.millisToPosix 1786013400000
                        }
                in
                Pages.Guild.encodeMessageView input.isMobile input.isHovered input.containerWidth input.isEditing input.highlight input.time
                    |> Pages.Guild.decodeMessageView
                    |> Expect.equal input
        , Test.test "Discord thread name is left as is when it's short enough" <|
            \_ ->
                DiscordSync.threadName "Hello world!"
                    |> Expect.equal "Hello world!"
        , Test.test "Discord thread name is shortened to 100 characters" <|
            \_ ->
                DiscordSync.threadName (String.repeat 50 "ab")
                    |> String.length
                    |> Expect.equal 100
        , Test.test "Discord thread name doesn't end with a partial word's trailing space" <|
            \_ ->
                DiscordSync.threadName (String.repeat 33 "abc ")
                    |> Expect.equal (String.repeat 24 "abc " ++ "abc")
        , Test.test "Discord thread name collapses whitespace onto a single line" <|
            \_ ->
                DiscordSync.threadName "  Hello\n\nworld!  "
                    |> Expect.equal "Hello world!"
        , Test.test "Discord thread name falls back to a placeholder when the message has no text" <|
            \_ ->
                DiscordSync.threadName "   "
                    |> Expect.equal "Thread"
        , Test.test "Commonly used emojis keeps a custom emoji the conversation can use" <|
            \_ ->
                User.commonlyUsedEmojis
                    (SeqSet.singleton usableCustomEmoji)
                    (User.addRecentlyUsedEmojis
                        (List.repeat 3 (EmojiOrCustomEmoji_CustomEmoji usableCustomEmoji))
                        Backend.adminUser
                    )
                    |> List.map Tuple.first
                    |> Expect.equal
                        [ EmojiOrCustomEmoji_CustomEmoji usableCustomEmoji
                        , EmojiOrCustomEmoji_Emoji Emoji.heart
                        , EmojiOrCustomEmoji_Emoji Emoji.thumbsUp
                        , EmojiOrCustomEmoji_Emoji Emoji.smiley
                        ]
        , Test.test "Commonly used emojis drops a custom emoji the conversation can't use" <|
            \_ ->
                User.commonlyUsedEmojis
                    (SeqSet.singleton usableCustomEmoji)
                    (User.addRecentlyUsedEmojis
                        (List.repeat 5 (EmojiOrCustomEmoji_CustomEmoji unusableCustomEmoji))
                        Backend.adminUser
                    )
                    |> List.map Tuple.first
                    |> Expect.equal
                        [ EmojiOrCustomEmoji_Emoji Emoji.heart
                        , EmojiOrCustomEmoji_Emoji Emoji.thumbsUp
                        , EmojiOrCustomEmoji_Emoji Emoji.smiley
                        ]
        , Test.describe
            "Parse device from user agent"
            (List.map
                (\( userAgentString, expected ) ->
                    Test.test (UserAgent.deviceToString expected ++ ": " ++ userAgentString) <|
                        \_ ->
                            UserAgent.parseUserAgent userAgentString
                                |> .device
                                |> Expect.equal expected
                )
                [ ( "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
                  , UserAgent.IPhone
                  )
                , ( "Mozilla/5.0 (iPad; CPU OS 12_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1 Mobile/15E148 Safari/604.1"
                  , UserAgent.IPad
                  )
                , ( "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36"
                  , UserAgent.AndroidPhone
                  )
                , ( "Mozilla/5.0 (Linux; Android 13; SM-X200) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
                  , UserAgent.AndroidTablet
                  )
                , ( "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0"
                  , UserAgent.Windows
                  )
                , ( "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15"
                  , UserAgent.MacOS
                  )
                , ( "Mozilla/5.0 (X11; CrOS x86_64 14541.0.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
                  , UserAgent.ChromeOS
                  )
                , ( "Mozilla/5.0 (X11; Linux x86_64; rv:124.0) Gecko/20100101 Firefox/124.0"
                  , UserAgent.Linux
                  )
                , ( "Mozilla/5.0 (Unknown; Mobile) SomeBrowser/1.0"
                  , UserAgent.Mobile
                  )
                , ( "Mozilla/5.0 (Unknown; Tablet) SomeBrowser/1.0"
                  , UserAgent.Tablet
                  )
                , ( "SomeBrowser/1.0"
                  , UserAgent.Desktop
                  )
                ]
            )
        ]


usableCustomEmoji : Id CustomEmojiId
usableCustomEmoji =
    Id.fromInt 1


unusableCustomEmoji : Id CustomEmojiId
unusableCustomEmoji =
    Id.fromInt 2


{-| A message that gives away the sender's own private key is caught on the way out.

The account used here is built from a fixed private key, so the public key it is checked
against is the one that really pairs with it rather than one written down by hand.

-}
redactPrivateKeysTests : Test
redactPrivateKeysTests =
    let
        privateKey : X25519.PrivateKey
        privateKey =
            case X25519.privateKeyFromListInt (List.repeat 8 305419896) of
                Just key ->
                    key

                Nothing ->
                    Debug.todo "Eight words is enough for a private key"

        privateKeyText : String
        privateKeyText =
            X25519.privateKeyToString privateKey

        account : { publicKey : Maybe X25519.PublicKey }
        account =
            { publicKey = Just (X25519.toPublicKey privateKey) }

        redact : { publicKey : Maybe X25519.PublicKey } -> String -> String
        redact user text =
            case String.Nonempty.fromString text of
                Just nonempty ->
                    User.redactPrivateKeys user nonempty |> String.Nonempty.toString

                Nothing ->
                    "the test wrote an empty message"

        warning : String
        warning =
            "*don't reveal your private key!*"
    in
    Test.describe "Redacting a private key from a message"
        [ Test.test "the key on its own is replaced"
            (\_ -> redact account privateKeyText |> Expect.equal warning)
        , Test.test "the rest of the message is left alone"
            (\_ ->
                redact account ("here it is " ++ privateKeyText ++ " don't tell anyone")
                    |> Expect.equal ("here it is " ++ warning ++ " don't tell anyone")
            )
        , Test.test "line breaks and runs of spaces survive"
            (\_ ->
                redact account ("one\n\ntwo   " ++ privateKeyText ++ "\nthree")
                    |> Expect.equal ("one\n\ntwo   " ++ warning ++ "\nthree")
            )
        , Test.test "every mention of it goes"
            (\_ ->
                redact account (privateKeyText ++ " and again " ++ privateKeyText)
                    |> Expect.equal (warning ++ " and again " ++ warning)
            )
        , Test.test "somebody else's private key is not this account's to worry about"
            (\_ ->
                let
                    otherKey : String
                    otherKey =
                        X25519.privateKeyFromListInt (List.repeat 8 987654321)
                            |> Maybe.map X25519.privateKeyToString
                            |> Maybe.withDefault "no key"
                in
                redact account otherKey |> Expect.equal otherKey
            )
        , Test.test "the public key is fine to share"
            (\_ ->
                let
                    publicKeyText : String
                    publicKeyText =
                        X25519.toPublicKey privateKey |> X25519.publicKeyToString
                in
                redact account publicKeyText |> Expect.equal publicKeyText
            )
        , Test.test "an ordinary message ending in = is left alone"
            (\_ -> redact account "the answer is x =" |> Expect.equal "the answer is x =")
        , Test.test "an account with no key pair has nothing to redact"
            (\_ ->
                redact { publicKey = Nothing } privateKeyText |> Expect.equal privateKeyText
            )
        ]
