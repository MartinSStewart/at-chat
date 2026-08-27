module MiscTests exposing (tests)

import Backend
import DiscordSync
import Effect.Time as Time
import Emoji exposing (EmojiOrCustomEmoji(..))
import Expect
import Id exposing (CustomEmojiId, Id)
import Pages.Guild exposing (HighlightMessage(..), IsHovered(..))
import SeqSet
import String.Nonempty
import Test exposing (Test)
import User
import UserAgent
import X25519


tests : Test
tests =
    Test.describe
        "Misc tests"
        [ redactPrivateKeysTests
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
