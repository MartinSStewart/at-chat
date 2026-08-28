module RichText exposing
    ( DiscordCustomEmojiIdAndName
    , Domain(..)
    , EmailConfig
    , EscapedChar(..)
    , HasLeadingLineBreak(..)
    , HeadingLevel(..)
    , Language(..)
    , Modifiers(..)
    , PressedImageData
    , PressedImageId(..)
    , RichText(..)
    , RichTextState
    , attachedFilePrefix
    , attachedFileSuffix
    , attachments
    , bigEmojiFont
    , customEmojis
    , customEmojisFromDiscord
    , dateAndTimeToString
    , discordCharsLeft
    , domainToString
    , emailView
    , emojisAndCustomEmojis
    , emptyPlaceholder
    , escapedCharToString
    , fromDiscord
    , fromNonemptyString
    , hasLargeContent
    , hyperlinks
    , maxLength
    , mentionsUser
    , preview
    , removeAttachedFile
    , spoilerAttachedFile
    , stickers
    , stringToStickersAndCustomEmojis
    , textInputView
    , timestampToDiscordString
    , timestampToString
    , toDiscord
    , toString
    , toStringWithGetter
    , tryParseTimestamp
    , unspoilerAttachedFile
    , urlToDomain
    , view
    )

import Array exposing (Array)
import Basics.Extra
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import CustomEmoji exposing (CustomEmojiData, EmojiName)
import Dict exposing (Dict)
import Discord exposing (EmbedType(..))
import Drawing exposing (Drawing)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Time as Time
import Email.Html
import Email.Html.Attributes
import Embed exposing (Embed(..), EmbedData)
import Emoji exposing (EmojiOrCustomEmoji(..))
import FileName
import FileStatus exposing (FileData, FileId, FileMetadata(..), VideoMetadata)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Icons
import Id exposing (CustomEmojiId, Id, StickerId)
import Json.Decode
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import MyUi
import NonemptyExtra
import OneToOne exposing (OneToOne)
import PersonName exposing (PersonName)
import Point2d exposing (Point2d)
import Range exposing (Range)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Set
import Sticker exposing (StickerData)
import String.Nonempty exposing (NonemptyString(..))
import TimeInMinutes exposing (TimeInMinutes)
import Touch exposing (ScreenCoordinate)
import UInt64
import Url exposing (Protocol(..), Url)
import UserColor exposing (UserColor)


{-| CSS background that hides spoilered content until it's revealed
-}
spoilerBackground : String
spoilerBackground =
    MyUi.colorToStyle MyUi.black


codeBackground : String
codeBackground =
    MyUi.colorToStyle (MyUi.colorWithAlpha 0.5 MyUi.background1)


codeBorder : String
codeBorder =
    "rgb(37,41,51)"


{-| The border and left/right padding of a code block. Named because scaling ascii art has
to subtract them from the container to know how much room the text actually gets.
-}
codeBorderWidth : Int
codeBorderWidth =
    1


codePaddingX : Int
codePaddingX =
    4


{-| Blue bar drawn along the left edge of block quotes and embeds
-}
accentBarColor : String
accentBarColor =
    "rgb(80,120,200)"


hyperlinkColor : String
hyperlinkColor =
    "rgb(66,133,244)"


type RichText userId
    = UserMention userId
    | NormalText Char String
    | Bold (Nonempty (RichText userId))
    | Italic (Nonempty (RichText userId))
    | Underline (Nonempty (RichText userId))
    | Strikethrough (Nonempty (RichText userId))
    | Spoiler (Nonempty (RichText userId))
    | BlockQuote HasLeadingLineBreak (List (RichText userId))
    | Heading HeadingLevel HasLeadingLineBreak (Nonempty (RichText userId))
    | Hyperlink Url
    | MarkdownLink NonemptyString Url
    | InlineCode Char String
    | CodeBlock Language String
    | AttachedFile (Id FileId)
    | EscapedChar EscapedChar
    | Sticker (Id StickerId)
    | CustomEmoji (Id CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (Nonempty (List (RichText userId)))
    | Timestamp TimeInMinutes


type HasLeadingLineBreak
    = HasLeadingLineBreak
    | NoLeadingLineBreak


type HeadingLevel
    = H1
    | H2
    | H3
    | Small


type EscapedChar
    = EscapedSquareBracket
    | EscapedBackslash
    | EscapedBacktick
    | EscapedAtSymbol
    | EscapedBold
    | EscapedItalic
      -- We don't include EscapedUnderline because it has the same start character as EscapedItalic
    | EscapedStrikethrough
    | EscapedSpoilered


allEscapedChars : List EscapedChar
allEscapedChars =
    [ EscapedSquareBracket
    , EscapedBackslash
    , EscapedBacktick
    , EscapedAtSymbol
    , EscapedBold
    , EscapedItalic
    , EscapedStrikethrough
    , EscapedSpoilered
    ]


escapedCharToString : EscapedChar -> String
escapedCharToString escaped =
    case escaped of
        EscapedSquareBracket ->
            "["

        EscapedBackslash ->
            "\\"

        EscapedBacktick ->
            "`"

        EscapedAtSymbol ->
            "@"

        EscapedBold ->
            "*"

        EscapedItalic ->
            "_"

        EscapedStrikethrough ->
            "~"

        EscapedSpoilered ->
            "|"


type Language
    = Language NonemptyString
    | NoLanguage


isAsciiArt : Language -> Bool
isAsciiArt language =
    case language of
        Language name ->
            String.toLower (String.Nonempty.toString name) == "ascii"

        NoLanguage ->
            False


{-| ascii.ttf is drawn on a grid 18 pixels to the em and 10 to the character, and only comes
out sharp when one of those pixels covers a whole number of device pixels. Use the largest
whole number that still lets the widest line fit the room the code block has, which is the
container less its border and padding. One drawn pixel per device pixel is the floor; art
too wide for that overflows rather than turning blurry.
-}
asciiFontSize : Int -> Float -> String -> String
asciiFontSize containerWidth dpi text =
    let
        columns : Int
        columns =
            String.split "\n" text
                |> List.map String.length
                |> List.maximum
                |> Maybe.withDefault 1
                |> max 1

        rows =
            String.indexes "\n" text |> List.length |> max 1

        roomInDevicePixels : Int
        roomInDevicePixels =
            (containerWidth - 2 * (codeBorderWidth + codePaddingX)) |> toFloat |> (*) dpi |> floor

        scale : Int
        scale =
            min (400 // (18 * rows)) (roomInDevicePixels // (10 * columns)) |> clamp 1 (round (2 * dpi))
    in
    String.fromFloat (18 * toFloat scale / dpi) ++ "px"


normalTextFromNonempty : NonemptyString -> RichText userId
normalTextFromNonempty text =
    NormalText (String.Nonempty.head text) (String.Nonempty.tail text)


spoilerAttachedFile : Id FileId -> Nonempty (RichText userId) -> Nonempty (RichText userId)
spoilerAttachedFile fileId nonempty =
    List.Nonempty.map
        (\richText ->
            case richText of
                NormalText _ _ ->
                    richText

                UserMention _ ->
                    richText

                Bold nonempty2 ->
                    spoilerAttachedFile fileId nonempty2 |> Bold

                Italic nonempty2 ->
                    spoilerAttachedFile fileId nonempty2 |> Italic

                Underline nonempty2 ->
                    spoilerAttachedFile fileId nonempty2 |> Underline

                Strikethrough nonempty2 ->
                    spoilerAttachedFile fileId nonempty2 |> Strikethrough

                Spoiler nonempty2 ->
                    spoilerAttachedFile fileId nonempty2 |> Spoiler

                BlockQuote a list ->
                    case List.Nonempty.fromList list of
                        Just nonempty2 ->
                            spoilerAttachedFile fileId nonempty2 |> List.Nonempty.toList |> BlockQuote a

                        Nothing ->
                            richText

                Heading level a nonempty2 ->
                    spoilerAttachedFile fileId nonempty2 |> Heading level a

                Hyperlink _ ->
                    richText

                MarkdownLink _ _ ->
                    richText

                InlineCode _ _ ->
                    richText

                CodeBlock _ _ ->
                    richText

                AttachedFile id ->
                    if id == fileId then
                        Spoiler (Nonempty (AttachedFile fileId) [])

                    else
                        richText

                EscapedChar _ ->
                    richText

                Sticker _ ->
                    richText

                CustomEmoji _ ->
                    richText

                BulletPoint a items ->
                    BulletPoint a (List.Nonempty.map (mapBulletItem (spoilerAttachedFile fileId)) items)

                Timestamp _ ->
                    richText
        )
        nonempty


unspoilerAttachedFile : Id FileId -> Nonempty (RichText userId) -> Nonempty (RichText userId)
unspoilerAttachedFile fileId nonempty =
    let
        helper : Nonempty (RichText userId) -> ( Bool, Nonempty (RichText userId) )
        helper nonempty2 =
            let
                unspoilered =
                    unspoilerAttachedFileHelper nonempty2
            in
            ( List.Nonempty.any (\( removeSpoiler, _ ) -> removeSpoiler) unspoilered
            , List.Nonempty.toList unspoilered
                |> List.Extra.groupWhile
                    (\( removeSpoilerA, _ ) ( removeSpoilerB, _ ) ->
                        removeSpoilerA == removeSpoilerB
                    )
                |> List.concatMap
                    (\( ( removeSpoiler, head ), rest ) ->
                        if removeSpoiler then
                            head :: List.map Tuple.second rest

                        else
                            [ Spoiler (Nonempty head (List.map Tuple.second rest)) ]
                    )
                |> List.Nonempty.fromList
                |> Maybe.withDefault nonempty2
            )

        unspoilerAttachedFileHelper : Nonempty (RichText userId) -> Nonempty ( Bool, RichText userId )
        unspoilerAttachedFileHelper nonempty2 =
            List.Nonempty.concatMap
                (\richText ->
                    case richText of
                        NormalText _ _ ->
                            Nonempty ( False, richText ) []

                        UserMention _ ->
                            Nonempty ( False, richText ) []

                        Bold nonempty3 ->
                            Nonempty (helper nonempty3 |> Tuple.mapSecond Bold) []

                        Italic nonempty3 ->
                            Nonempty (helper nonempty3 |> Tuple.mapSecond Italic) []

                        Underline nonempty3 ->
                            Nonempty (helper nonempty3 |> Tuple.mapSecond Underline) []

                        Strikethrough nonempty3 ->
                            Nonempty (helper nonempty3 |> Tuple.mapSecond Strikethrough) []

                        Spoiler _ ->
                            -- This shouldn't be reachable since spoilers can't be nested
                            Nonempty ( False, richText ) []

                        BlockQuote hasLeadingLineBreak list ->
                            case List.Nonempty.fromList list of
                                Just nonempty3 ->
                                    Nonempty
                                        (helper nonempty3
                                            |> Tuple.mapSecond (\a -> BlockQuote hasLeadingLineBreak (List.Nonempty.toList a))
                                        )
                                        []

                                Nothing ->
                                    Nonempty ( False, richText ) []

                        Heading level hasLeadingLineBreak nonempty3 ->
                            Nonempty (helper nonempty3 |> Tuple.mapSecond (\a -> Heading level hasLeadingLineBreak a)) []

                        Hyperlink _ ->
                            Nonempty ( False, richText ) []

                        MarkdownLink _ _ ->
                            Nonempty ( False, richText ) []

                        InlineCode _ _ ->
                            Nonempty ( False, richText ) []

                        CodeBlock _ _ ->
                            Nonempty ( False, richText ) []

                        AttachedFile id ->
                            if id == fileId then
                                Nonempty ( True, richText ) []

                            else
                                Nonempty ( False, richText ) []

                        EscapedChar _ ->
                            Nonempty ( False, richText ) []

                        Sticker _ ->
                            Nonempty ( False, richText ) []

                        CustomEmoji _ ->
                            Nonempty ( False, richText ) []

                        BulletPoint hasLeadingLineBreak items ->
                            Nonempty
                                ( False
                                , BulletPoint hasLeadingLineBreak (List.Nonempty.map (mapBulletItem (unspoilerAttachedFile fileId)) items)
                                )
                                []

                        Timestamp _ ->
                            Nonempty ( False, richText ) []
                )
                nonempty2
    in
    List.Nonempty.concatMap
        (\richText ->
            case richText of
                NormalText _ _ ->
                    Nonempty richText []

                UserMention _ ->
                    Nonempty richText []

                Bold nonempty2 ->
                    Nonempty (Bold (unspoilerAttachedFile fileId nonempty2)) []

                Italic nonempty2 ->
                    Nonempty (Italic (unspoilerAttachedFile fileId nonempty2)) []

                Underline nonempty2 ->
                    Nonempty (Underline (unspoilerAttachedFile fileId nonempty2)) []

                Strikethrough nonempty2 ->
                    Nonempty (Strikethrough (unspoilerAttachedFile fileId nonempty2)) []

                Spoiler nonempty2 ->
                    let
                        ( removeSpoiler, nonempty4 ) =
                            helper nonempty2
                    in
                    if removeSpoiler then
                        nonempty4

                    else
                        Nonempty richText []

                BlockQuote a list ->
                    case List.Nonempty.fromList list of
                        Just nonempty2 ->
                            Nonempty (BlockQuote a (unspoilerAttachedFile fileId nonempty2 |> List.Nonempty.toList)) []

                        Nothing ->
                            Nonempty richText []

                Heading level a nonempty2 ->
                    Nonempty (Heading level a (unspoilerAttachedFile fileId nonempty2)) []

                Hyperlink _ ->
                    Nonempty richText []

                MarkdownLink _ _ ->
                    Nonempty richText []

                InlineCode _ _ ->
                    Nonempty richText []

                CodeBlock _ _ ->
                    Nonempty richText []

                AttachedFile _ ->
                    Nonempty richText []

                EscapedChar _ ->
                    Nonempty richText []

                Sticker _ ->
                    Nonempty richText []

                CustomEmoji _ ->
                    Nonempty richText []

                BulletPoint hasLeadingLineBreak items ->
                    Nonempty
                        (BulletPoint hasLeadingLineBreak (List.Nonempty.map (mapBulletItem (unspoilerAttachedFile fileId)) items))
                        []

                Timestamp _ ->
                    Nonempty richText []
        )
        nonempty


removeAttachedFile : (Id FileId -> Bool) -> Nonempty (RichText userId) -> Maybe (Nonempty (RichText userId))
removeAttachedFile shouldRemove list =
    List.filterMap
        (\richText ->
            case richText of
                NormalText _ _ ->
                    Just richText

                UserMention _ ->
                    Just richText

                Bold nonempty ->
                    removeAttachedFile shouldRemove nonempty |> Maybe.map Bold

                Italic nonempty ->
                    removeAttachedFile shouldRemove nonempty |> Maybe.map Italic

                Underline nonempty ->
                    removeAttachedFile shouldRemove nonempty |> Maybe.map Underline

                Strikethrough nonempty ->
                    removeAttachedFile shouldRemove nonempty |> Maybe.map Strikethrough

                Spoiler nonempty ->
                    removeAttachedFile shouldRemove nonempty |> Maybe.map Spoiler

                BlockQuote a list2 ->
                    case List.Nonempty.fromList list2 of
                        Just nonempty ->
                            case removeAttachedFile shouldRemove nonempty of
                                Just nonempty2 ->
                                    BlockQuote a (List.Nonempty.toList nonempty2) |> Just

                                Nothing ->
                                    BlockQuote a [] |> Just

                        Nothing ->
                            Just richText

                Heading level a nonempty ->
                    removeAttachedFile shouldRemove nonempty |> Maybe.map (Heading level a)

                Hyperlink _ ->
                    Just richText

                MarkdownLink _ _ ->
                    Just richText

                InlineCode _ _ ->
                    Just richText

                CodeBlock _ _ ->
                    Just richText

                AttachedFile fileId ->
                    if shouldRemove fileId then
                        Nothing

                    else
                        Just richText

                EscapedChar _ ->
                    Just richText

                Sticker _ ->
                    Just richText

                CustomEmoji _ ->
                    Just richText

                BulletPoint a items ->
                    BulletPoint
                        a
                        (List.Nonempty.map
                            (\item ->
                                case List.Nonempty.fromList item of
                                    Just nonempty ->
                                        removeAttachedFile shouldRemove nonempty
                                            |> Maybe.map List.Nonempty.toList
                                            |> Maybe.withDefault []

                                    Nothing ->
                                        []
                            )
                            items
                        )
                        |> Just

                Timestamp _ ->
                    Just richText
        )
        (List.Nonempty.toList list)
        |> List.Nonempty.fromList


hyperlinks : Nonempty (RichText userId) -> List Url
hyperlinks nonempty =
    List.concatMap
        (\richText ->
            case richText of
                Hyperlink data ->
                    [ data ]

                MarkdownLink _ url ->
                    [ url ]

                UserMention _ ->
                    []

                NormalText _ _ ->
                    []

                Bold nonempty2 ->
                    hyperlinks nonempty2

                Italic nonempty2 ->
                    hyperlinks nonempty2

                Underline nonempty2 ->
                    hyperlinks nonempty2

                Strikethrough nonempty2 ->
                    hyperlinks nonempty2

                Spoiler nonempty2 ->
                    hyperlinks nonempty2

                BlockQuote _ list ->
                    List.Nonempty.fromList list |> Maybe.map hyperlinks |> Maybe.withDefault []

                Heading _ _ nonempty2 ->
                    hyperlinks nonempty2

                InlineCode _ _ ->
                    []

                CodeBlock _ _ ->
                    []

                AttachedFile _ ->
                    []

                EscapedChar _ ->
                    []

                Sticker _ ->
                    []

                CustomEmoji _ ->
                    []

                BulletPoint _ items ->
                    List.concatMap (bulletItemConcatMap hyperlinks) (List.Nonempty.toList items)

                Timestamp _ ->
                    []
        )
        (List.Nonempty.toList nonempty)


attachments : Nonempty (RichText userId) -> List { attachmentId : Id FileId, isSpoilered : Bool }
attachments nonempty =
    attachmentsHelper False nonempty


attachmentsHelper : Bool -> Nonempty (RichText userId) -> List { attachmentId : Id FileId, isSpoilered : Bool }
attachmentsHelper isSpoilered nonempty =
    List.concatMap
        (\richText ->
            case richText of
                Hyperlink _ ->
                    []

                MarkdownLink _ _ ->
                    []

                UserMention _ ->
                    []

                NormalText _ _ ->
                    []

                Bold nonempty2 ->
                    attachmentsHelper isSpoilered nonempty2

                Italic nonempty2 ->
                    attachmentsHelper isSpoilered nonempty2

                Underline nonempty2 ->
                    attachmentsHelper isSpoilered nonempty2

                Strikethrough nonempty2 ->
                    attachmentsHelper isSpoilered nonempty2

                Spoiler nonempty2 ->
                    attachmentsHelper True nonempty2

                BlockQuote _ list ->
                    List.Nonempty.fromList list |> Maybe.map (attachmentsHelper isSpoilered) |> Maybe.withDefault []

                Heading _ _ nonempty2 ->
                    attachmentsHelper isSpoilered nonempty2

                InlineCode _ _ ->
                    []

                CodeBlock _ _ ->
                    []

                AttachedFile fileId ->
                    [ { attachmentId = fileId, isSpoilered = isSpoilered } ]

                EscapedChar _ ->
                    []

                Sticker _ ->
                    []

                CustomEmoji _ ->
                    []

                BulletPoint _ items ->
                    List.concatMap (bulletItemConcatMap (attachmentsHelper isSpoilered)) (List.Nonempty.toList items)

                Timestamp _ ->
                    []
        )
        (List.Nonempty.toList nonempty)


customEmojis : Nonempty (RichText userId) -> List (Id CustomEmojiId)
customEmojis nonempty =
    List.concatMap
        (\richText ->
            case richText of
                Hyperlink _ ->
                    []

                MarkdownLink _ _ ->
                    []

                UserMention _ ->
                    []

                NormalText _ _ ->
                    []

                Bold nonempty2 ->
                    customEmojis nonempty2

                Italic nonempty2 ->
                    customEmojis nonempty2

                Underline nonempty2 ->
                    customEmojis nonempty2

                Strikethrough nonempty2 ->
                    customEmojis nonempty2

                Spoiler nonempty2 ->
                    customEmojis nonempty2

                BlockQuote _ list ->
                    List.Nonempty.fromList list |> Maybe.map customEmojis |> Maybe.withDefault []

                Heading _ _ nonempty2 ->
                    customEmojis nonempty2

                InlineCode _ _ ->
                    []

                CodeBlock _ _ ->
                    []

                AttachedFile _ ->
                    []

                EscapedChar _ ->
                    []

                Sticker _ ->
                    []

                CustomEmoji customEmojiId ->
                    [ customEmojiId ]

                BulletPoint _ items ->
                    List.concatMap (bulletItemConcatMap customEmojis) (List.Nonempty.toList items)

                Timestamp _ ->
                    []
        )
        (List.Nonempty.toList nonempty)


emojisAndCustomEmojis : Emoji.CachedEmojiData -> Nonempty (RichText userId) -> List EmojiOrCustomEmoji
emojisAndCustomEmojis emojiData nonempty =
    List.concatMap
        (\richText ->
            case richText of
                Hyperlink _ ->
                    []

                MarkdownLink text _ ->
                    Emoji.emojisInText emojiData (String.Nonempty.toString text) |> List.map EmojiOrCustomEmoji_Emoji

                UserMention _ ->
                    []

                NormalText char rest ->
                    Emoji.emojisInText emojiData (String.fromChar char ++ rest)
                        |> List.map EmojiOrCustomEmoji_Emoji

                Bold nonempty2 ->
                    emojisAndCustomEmojis emojiData nonempty2

                Italic nonempty2 ->
                    emojisAndCustomEmojis emojiData nonempty2

                Underline nonempty2 ->
                    emojisAndCustomEmojis emojiData nonempty2

                Strikethrough nonempty2 ->
                    emojisAndCustomEmojis emojiData nonempty2

                Spoiler nonempty2 ->
                    emojisAndCustomEmojis emojiData nonempty2

                BlockQuote _ list ->
                    List.Nonempty.fromList list |> Maybe.map (emojisAndCustomEmojis emojiData) |> Maybe.withDefault []

                Heading _ _ nonempty2 ->
                    emojisAndCustomEmojis emojiData nonempty2

                InlineCode char rest ->
                    Emoji.emojisInText emojiData (String.fromChar char ++ rest)
                        |> List.map EmojiOrCustomEmoji_Emoji

                CodeBlock _ code ->
                    Emoji.emojisInText emojiData code |> List.map EmojiOrCustomEmoji_Emoji

                AttachedFile _ ->
                    []

                EscapedChar _ ->
                    []

                Sticker _ ->
                    []

                CustomEmoji customEmojiId ->
                    [ EmojiOrCustomEmoji_CustomEmoji customEmojiId ]

                BulletPoint _ items ->
                    List.concatMap (bulletItemConcatMap (emojisAndCustomEmojis emojiData)) (List.Nonempty.toList items)

                Timestamp _ ->
                    []
        )
        (List.Nonempty.toList nonempty)


stickers : Nonempty (RichText userId) -> List (Id StickerId)
stickers nonempty =
    List.concatMap
        (\richText ->
            case richText of
                Hyperlink _ ->
                    []

                MarkdownLink _ _ ->
                    []

                UserMention _ ->
                    []

                NormalText _ _ ->
                    []

                Bold nonempty2 ->
                    stickers nonempty2

                Italic nonempty2 ->
                    stickers nonempty2

                Underline nonempty2 ->
                    stickers nonempty2

                Strikethrough nonempty2 ->
                    stickers nonempty2

                Spoiler nonempty2 ->
                    stickers nonempty2

                BlockQuote _ list ->
                    List.Nonempty.fromList list |> Maybe.map stickers |> Maybe.withDefault []

                Heading _ _ nonempty2 ->
                    stickers nonempty2

                InlineCode _ _ ->
                    []

                CodeBlock _ _ ->
                    []

                AttachedFile _ ->
                    []

                EscapedChar _ ->
                    []

                Sticker stickerId ->
                    [ stickerId ]

                CustomEmoji _ ->
                    []

                BulletPoint _ items ->
                    List.concatMap (bulletItemConcatMap stickers) (List.Nonempty.toList items)

                Timestamp _ ->
                    []
        )
        (List.Nonempty.toList nonempty)


toStringWithGetter : Time.Zone -> (a -> String) -> Bool -> SeqDict userId a -> Nonempty (RichText userId) -> String
toStringWithGetter timezone userToString emojisForStickersAndAttachments users nonempty =
    toStringHelper timezone userToString emojisForStickersAndAttachments users (List.Nonempty.toList nonempty)


blockQuoteToString : HasLeadingLineBreak -> String -> String
blockQuoteToString hasLeadingLineBreak inner =
    (case hasLeadingLineBreak of
        NoLeadingLineBreak ->
            ""

        HasLeadingLineBreak ->
            "\n"
    )
        ++ (String.split "\n" inner
                |> List.map
                    (\line ->
                        if String.isEmpty line then
                            "> "

                        else
                            "> " ++ line
                    )
                |> String.join "\n"
           )


headingLevelToMarker : HeadingLevel -> String
headingLevelToMarker level =
    case level of
        H1 ->
            "# "

        H2 ->
            "## "

        H3 ->
            "### "

        Small ->
            "-# "


headingToString : HasLeadingLineBreak -> HeadingLevel -> String -> String
headingToString hasLeadingLineBreak level inner =
    (case hasLeadingLineBreak of
        NoLeadingLineBreak ->
            ""

        HasLeadingLineBreak ->
            "\n"
    )
        ++ headingLevelToMarker level
        ++ inner


toString : Time.Zone -> Bool -> SeqDict userId { a | name : PersonName } -> Nonempty (RichText userId) -> String
toString timezone emojisForStickersAndAttachments users nonempty =
    toStringHelper
        timezone
        (\user -> PersonName.toString user.name)
        emojisForStickersAndAttachments
        users
        (List.Nonempty.toList nonempty)


maxLength : number
maxLength =
    2000


toStringHelper : Time.Zone -> (a -> String) -> Bool -> SeqDict userId a -> List (RichText userId) -> String
toStringHelper timezone userToString emojisForStickersAndAttachments users list =
    List.map
        (\richText ->
            case richText of
                NormalText char rest ->
                    String.cons char rest

                UserMention userId ->
                    case SeqDict.get userId users of
                        Just user ->
                            "@" ++ userToString user

                        Nothing ->
                            "@<missing>"

                Bold a ->
                    "*"
                        ++ toStringHelper timezone userToString emojisForStickersAndAttachments users (List.Nonempty.toList a)
                        ++ "*"

                Italic a ->
                    "_"
                        ++ toStringHelper timezone userToString emojisForStickersAndAttachments users (List.Nonempty.toList a)
                        ++ "_"

                Underline a ->
                    "__"
                        ++ toStringHelper timezone userToString emojisForStickersAndAttachments users (List.Nonempty.toList a)
                        ++ "__"

                Strikethrough a ->
                    "~~"
                        ++ toStringHelper timezone userToString emojisForStickersAndAttachments users (List.Nonempty.toList a)
                        ++ "~~"

                Spoiler a ->
                    "||"
                        ++ toStringHelper timezone userToString emojisForStickersAndAttachments users (List.Nonempty.toList a)
                        ++ "||"

                BlockQuote hasLeadingLineBreak a ->
                    blockQuoteToString
                        hasLeadingLineBreak
                        (toStringHelper timezone userToString emojisForStickersAndAttachments users a)

                Heading level hasLeadingLineBreak a ->
                    headingToString
                        hasLeadingLineBreak
                        level
                        (toStringHelper timezone userToString emojisForStickersAndAttachments users (List.Nonempty.toList a))

                Hyperlink data ->
                    Url.toString data

                MarkdownLink alias url ->
                    "[" ++ String.Nonempty.toString alias ++ "](" ++ Url.toString url ++ ")"

                InlineCode char rest ->
                    "`" ++ String.cons char rest ++ "`"

                CodeBlock language string ->
                    "```"
                        ++ (case language of
                                Language unknown ->
                                    String.Nonempty.toString unknown ++ "\n"

                                NoLanguage ->
                                    ""
                           )
                        ++ string
                        ++ "```"

                AttachedFile fileId ->
                    if emojisForStickersAndAttachments then
                        "🖼️"

                    else
                        attachedFilePrefix ++ Id.toString fileId ++ attachedFileSuffix

                EscapedChar char ->
                    "\\" ++ escapedCharToString char

                Sticker id ->
                    if emojisForStickersAndAttachments then
                        "🖼️"

                    else
                        Sticker.idToString id

                CustomEmoji id ->
                    CustomEmoji.idToString id

                BulletPoint hasLeadingLineBreak items ->
                    (case hasLeadingLineBreak of
                        NoLeadingLineBreak ->
                            ""

                        HasLeadingLineBreak ->
                            "\n"
                    )
                        ++ (List.Nonempty.toList items
                                |> List.map
                                    (\item ->
                                        "* " ++ toStringHelper timezone userToString emojisForStickersAndAttachments users item
                                    )
                                |> String.join "\n"
                           )

                Timestamp time ->
                    dateAndTimeToString timezone time
        )
        list
        |> String.concat


type alias EmailConfig userId =
    { attachedFiles : SeqDict (Id FileId) FileData
    , userToString : userId -> String
    }


{-| Render rich text into email-safe html. This is a port of `view`/`viewHelper`
that keeps the same formatting `state` and `dropNextLineBreak` handling and reuses
the same inline styling, but strips out everything email can't support: the
large-content vs preview distinction, all event handling, link embeds, and
image/video/audio rendering. Mentions are resolved with `userToString`; spoilers
are always shown in their hidden form (email can't reveal them on click); and
attachments, stickers and custom emojis become simple placeholders since the
lookup tables needed to render them aren't available here.
-}
emailView : EmailConfig userId -> Nonempty (RichText userId) -> List Email.Html.Html
emailView config nonempty =
    emailViewHelper
        config
        False
        { spoiler = False, underline = False, italic = False, bold = False, strikethrough = False }
        nonempty
        |> Tuple.second


emailContainerWidth : number
emailContainerWidth =
    500


emailViewHelper :
    EmailConfig userId
    -> Bool
    -> RichTextState
    -> Nonempty (RichText userId)
    -> ( Bool, List Email.Html.Html )
emailViewHelper config dropNextLineBreak state nonempty =
    List.foldl
        (\item ( dropNextLineBreak2, currentList ) ->
            case item of
                UserMention userId ->
                    ( False, currentList ++ [ emailUserLabel (config.userToString userId) ] )

                NormalText char text ->
                    ( False
                    , currentList
                        ++ emailNormalTextView
                            (if dropNextLineBreak2 && char == '\n' then
                                text

                             else
                                String.cons char text
                            )
                            state
                    )

                Italic nonempty2 ->
                    let
                        ( dropNextLineBreak3, list ) =
                            emailViewHelper config dropNextLineBreak2 { state | italic = True } nonempty2
                    in
                    ( dropNextLineBreak3, currentList ++ list )

                Underline nonempty2 ->
                    let
                        ( dropNextLineBreak3, list ) =
                            emailViewHelper config dropNextLineBreak2 { state | underline = True } nonempty2
                    in
                    ( dropNextLineBreak3, currentList ++ list )

                Bold nonempty2 ->
                    let
                        ( dropNextLineBreak3, list ) =
                            emailViewHelper config dropNextLineBreak2 { state | bold = True } nonempty2
                    in
                    ( dropNextLineBreak3, currentList ++ list )

                Strikethrough nonempty2 ->
                    let
                        ( dropNextLineBreak3, list ) =
                            emailViewHelper config dropNextLineBreak2 { state | strikethrough = True } nonempty2
                    in
                    ( dropNextLineBreak3, currentList ++ list )

                Spoiler nonempty2 ->
                    let
                        -- Email can't reveal spoilers on click, so always render the hidden variant.
                        ( dropNextLineBreak3, list ) =
                            emailViewHelper config dropNextLineBreak2 { state | spoiler = True } nonempty2
                    in
                    ( dropNextLineBreak3
                    , currentList
                        ++ [ Email.Html.span
                                [ Email.Html.Attributes.borderRadius "2px"
                                , Email.Html.Attributes.backgroundColor spoilerBackground
                                ]
                                list
                           ]
                    )

                BlockQuote _ list ->
                    let
                        ( _, list2 ) =
                            case List.Nonempty.fromList list of
                                Just nonempty2 ->
                                    emailViewHelper config True state nonempty2

                                Nothing ->
                                    ( True, [ Email.Html.text " " ] )
                    in
                    ( True
                    , currentList
                        ++ [ Email.Html.div
                                [ Email.Html.Attributes.borderLeft ("4px solid " ++ accentBarColor)
                                , Email.Html.Attributes.padding "2px 8px"
                                ]
                                list2
                           ]
                    )

                Heading level _ nonempty2 ->
                    let
                        ( _, list2 ) =
                            emailViewHelper config True state nonempty2

                        headingElement : Email.Html.Html
                        headingElement =
                            case level of
                                H1 ->
                                    Email.Html.h1
                                        [ Email.Html.Attributes.fontSize "2em"
                                        , Email.Html.Attributes.style "font-weight" "700"
                                        , Email.Html.Attributes.style "margin" "0"
                                        ]
                                        list2

                                H2 ->
                                    Email.Html.h2
                                        [ Email.Html.Attributes.fontSize "1.5em"
                                        , Email.Html.Attributes.style "font-weight" "700"
                                        , Email.Html.Attributes.style "margin" "0"
                                        ]
                                        list2

                                H3 ->
                                    Email.Html.h3
                                        [ Email.Html.Attributes.fontSize "1.25em"
                                        , Email.Html.Attributes.style "font-weight" "700"
                                        , Email.Html.Attributes.style "margin" "0"
                                        ]
                                        list2

                                Small ->
                                    Email.Html.div
                                        [ Email.Html.Attributes.fontSize "0.8em"
                                        , Email.Html.Attributes.color (MyUi.colorToStyle MyUi.font2)
                                        ]
                                        list2
                    in
                    ( True, currentList ++ [ headingElement ] )

                Hyperlink data ->
                    ( False, currentList ++ [ emailLinkView state (Url.toString data) (Url.toString data) ] )

                MarkdownLink alias url ->
                    ( False, currentList ++ [ emailLinkView state (Url.toString url) (String.Nonempty.toString alias) ] )

                InlineCode char rest ->
                    ( False
                    , currentList
                        ++ [ Email.Html.span
                                (List.filterMap identity
                                    [ emailAttrIf state.italic (Email.Html.Attributes.fontStyle "italic")
                                    , emailAttrIf state.underline (Email.Html.Attributes.style "text-decoration" "underline")
                                    , emailAttrIf state.bold (Email.Html.Attributes.style "text-shadow" "0.7px 0px 0px white")
                                    , emailAttrIf state.strikethrough (Email.Html.Attributes.style "text-decoration" "line-through")
                                    , emailAttrIf state.spoiler (Email.Html.Attributes.style "opacity" "0")
                                    ]
                                    ++ [ Email.Html.Attributes.backgroundColor codeBackground
                                       , Email.Html.Attributes.border (codeBorder ++ " solid 1px")
                                       , Email.Html.Attributes.padding "0 4px 0 4px"
                                       , Email.Html.Attributes.borderRadius "4px"
                                       , Email.Html.Attributes.fontFamily "monospace"
                                       ]
                                )
                                [ Email.Html.text (String.cons char rest) ]
                           ]
                    )

                CodeBlock language text ->
                    ( True
                    , currentList
                        ++ [ Email.Html.div
                                ([ Email.Html.Attributes.backgroundColor
                                    (if state.spoiler then
                                        spoilerBackground

                                     else
                                        codeBackground
                                    )
                                 , Email.Html.Attributes.border (codeBorder ++ " solid 1px")
                                 , Email.Html.Attributes.padding "0 4px 0 4px"
                                 , Email.Html.Attributes.borderRadius "4px"
                                 ]
                                    ++ (if isAsciiArt language then
                                            [ Email.Html.Attributes.fontFamily "'Courier New', monospace"
                                            , Email.Html.Attributes.lineHeight "1"
                                            ]

                                        else
                                            [ Email.Html.Attributes.fontFamily "monospace" ]
                                       )
                                )
                                [ if state.spoiler then
                                    Email.Html.span [ Email.Html.Attributes.style "opacity" "0" ] [ Email.Html.text text ]

                                  else
                                    Email.Html.text text
                                ]
                           ]
                    )

                AttachedFile fileId ->
                    case SeqDict.get fileId config.attachedFiles of
                        Just fileData ->
                            ( True
                            , currentList
                                ++ [ case fileData.metadata of
                                        Just (FileMetadata_Image { imageSize }) ->
                                            let
                                                ( width, height ) =
                                                    actualImageSize FileStatus.imageMaxHeight emailContainerWidth imageSize
                                            in
                                            if state.spoiler then
                                                Email.Html.div
                                                    [ Email.Html.Attributes.width (String.fromInt (round width) ++ "px")
                                                    , Email.Html.Attributes.height (String.fromInt (round height) ++ "px")
                                                    , Email.Html.Attributes.backgroundColor spoilerBackground
                                                    ]
                                                    []

                                            else
                                                let
                                                    thumbnailUrl =
                                                        FileStatus.thumbnailUrl
                                                            imageSize
                                                            fileData.contentType
                                                            fileData.fileHash
                                                in
                                                Email.Html.img
                                                    [ Email.Html.Attributes.src thumbnailUrl
                                                    , Email.Html.Attributes.style "display" "block"
                                                    , Email.Html.Attributes.width (String.fromInt (round width) ++ "px")
                                                    , Email.Html.Attributes.height (String.fromInt (round height) ++ "px")
                                                    ]
                                                    []

                                        Just (FileMetadata_Video _) ->
                                            emailFileDownloadView state.spoiler fileData

                                        Nothing ->
                                            emailFileDownloadView state.spoiler fileData
                                   ]
                            )

                        Nothing ->
                            ( False, currentList )

                EscapedChar char ->
                    ( False, currentList ++ [ Email.Html.text (escapedCharToString char) ] )

                Sticker _ ->
                    ( True, currentList ++ [ emailPlaceholder "🖼️" ] )

                CustomEmoji _ ->
                    ( False, currentList ++ [ emailPlaceholder "🙂" ] )

                BulletPoint _ items ->
                    let
                        ( _, listItems ) =
                            List.foldl
                                (\bulletItem ( _, acc ) ->
                                    case List.Nonempty.fromList bulletItem of
                                        Just nonempty2 ->
                                            let
                                                ( d3, html ) =
                                                    emailViewHelper config True state nonempty2
                                            in
                                            ( d3, html :: acc )

                                        Nothing ->
                                            ( True, acc )
                                )
                                ( dropNextLineBreak2, [] )
                                (List.Nonempty.toList items)
                                |> (\( a, acc ) -> ( a, List.reverse acc ))
                    in
                    ( True
                    , currentList
                        ++ [ Email.Html.ul
                                [ Email.Html.Attributes.style "margin" "0"
                                , Email.Html.Attributes.paddingLeft "24px"
                                ]
                                (List.map (Email.Html.li []) listItems)
                           ]
                    )

                Timestamp time ->
                    ( False
                    , currentList
                        ++ [ Email.Html.span
                                (List.filterMap identity
                                    [ emailAttrIf state.italic (Email.Html.Attributes.fontStyle "italic")
                                    , emailAttrIf state.underline (Email.Html.Attributes.style "text-decoration" "underline")
                                    , emailAttrIf state.bold (Email.Html.Attributes.style "text-shadow" "0.7px 0px 0px white")
                                    , emailAttrIf state.strikethrough (Email.Html.Attributes.style "text-decoration" "line-through")
                                    , emailAttrIf state.spoiler (Email.Html.Attributes.style "opacity" "0")
                                    ]
                                    ++ [ Email.Html.Attributes.backgroundColor codeBackground
                                       , Email.Html.Attributes.border (codeBorder ++ " solid 1px")
                                       , Email.Html.Attributes.padding "0 4px 0 4px"
                                       , Email.Html.Attributes.borderRadius "4px"
                                       ]
                                )
                                [ Email.Html.text (dateAndTimeToString Time.utc time ++ " (UTC)") ]
                           ]
                      --++ [ Html.span
                      --           [ emailAttrIf state.italic (Email.Html.Attributes.style "font-style" "italic")
                      --           , emailAttrIf state.underline (Email.Html.Attributes.style "text-decoration" "underline")
                      --           , emailAttrIf state.bold (Email.Html.Attributes.style "font-weight" "700")
                      --           , emailAttrIf state.strikethrough (Email.Html.Attributes.style "text-decoration" "line-through")
                      --           , emailAttrIf state.spoiler (Email.Html.Attributes.style "opacity" "0")
                      --           , -- Subdued like inline code, so a timestamp doesn't compete with the bright blue
                      --             -- of a user mention
                      --             Email.Html.Attributes.style "background-color" codeBackground
                      --           , Email.Html.Attributes.style "padding" "1px 3px"
                      --           , Email.Html.Attributes.style "border-radius" "3px"
                      --           , Email.Html.Attributes.style "white-space" "nowrap"
                      --           , -- Today's timestamps leave the date out, so hovering brings it back
                      --             Email.Html.Attributes.title (dateAndTimeToString timezone time)
                      --           ]
                      --           [ Email.Html.text (timestampToString now timezone time) ]
                      --   ]
                    )
        )
        ( dropNextLineBreak, [] )
        (List.Nonempty.toList nonempty)


emailAttrIf : Bool -> Email.Html.Attribute -> Maybe Email.Html.Attribute
emailAttrIf condition attribute =
    if condition then
        Just attribute

    else
        Nothing


emailNormalTextView : String -> RichTextState -> List Email.Html.Html
emailNormalTextView text state =
    [ Email.Html.span
        (List.filterMap identity
            [ emailAttrIf state.italic (Email.Html.Attributes.fontStyle "italic")
            , emailAttrIf state.underline (Email.Html.Attributes.style "text-decoration" "underline")
            , emailAttrIf state.bold (Email.Html.Attributes.style "font-weight" "700")
            , emailAttrIf state.strikethrough (Email.Html.Attributes.style "text-decoration" "line-through")
            , emailAttrIf state.spoiler (Email.Html.Attributes.style "opacity" "0")
            ]
        )
        [ Email.Html.text text ]
    ]


emailUserLabel : String -> Email.Html.Html
emailUserLabel name =
    Email.Html.span
        [ Email.Html.Attributes.backgroundColor (MyUi.colorToHex MyUi.userLabelBackground)
        , Email.Html.Attributes.padding "1px 1px 0 1px"
        , Email.Html.Attributes.color (MyUi.colorToHex MyUi.userLabelFontColor)
        , Email.Html.Attributes.borderRadius "2px"
        , Email.Html.Attributes.style "white-space" "nowrap"
        ]
        [ Email.Html.text ("@" ++ name) ]


emailLinkView : RichTextState -> String -> String -> Email.Html.Html
emailLinkView state url label =
    if state.spoiler then
        Email.Html.span
            (List.filterMap identity
                [ emailAttrIf state.italic (Email.Html.Attributes.fontStyle "italic")
                , emailAttrIf state.underline (Email.Html.Attributes.style "text-decoration" "underline")
                , emailAttrIf state.bold (Email.Html.Attributes.style "font-weight" "700")
                , emailAttrIf state.strikethrough (Email.Html.Attributes.style "text-decoration" "line-through")
                ]
                ++ [ Email.Html.Attributes.style "opacity" "0" ]
            )
            [ Email.Html.text label ]

    else
        Email.Html.a
            (List.filterMap identity
                [ emailAttrIf state.italic (Email.Html.Attributes.fontStyle "italic")
                , emailAttrIf state.underline (Email.Html.Attributes.style "text-decoration" "underline")
                , emailAttrIf state.bold (Email.Html.Attributes.style "font-weight" "700")
                , emailAttrIf state.strikethrough (Email.Html.Attributes.style "text-decoration" "line-through")
                ]
                ++ [ Email.Html.Attributes.href url
                   , Email.Html.Attributes.color hyperlinkColor
                   ]
            )
            [ Email.Html.text label ]


emailPlaceholder : String -> Email.Html.Html
emailPlaceholder label =
    Email.Html.span [] [ Email.Html.text label ]


{-| Email port of `fileDownloadView`: a labelled link to download a non-image
attachment. Drops the element id and download icon (which don't translate to
email) but keeps the same styling.
-}
emailFileDownloadView : Bool -> FileData -> Email.Html.Html
emailFileDownloadView isSpoilered fileData =
    Email.Html.a
        ([ Email.Html.Attributes.style "max-width" "284px"
         , Email.Html.Attributes.backgroundColor
            (if isSpoilered then
                spoilerBackground

             else
                MyUi.colorToStyle MyUi.background1
            )
         , Email.Html.Attributes.borderRadius "4px"
         , Email.Html.Attributes.border ("solid 1px " ++ MyUi.colorToStyle MyUi.border1)
         , Email.Html.Attributes.style "display" "block"
         , Email.Html.Attributes.fontSize "14px"
         , Email.Html.Attributes.padding "4px 8px 4px 8px"
         ]
            ++ (if isSpoilered then
                    [ Email.Html.Attributes.color "transparent" ]

                else
                    [ Email.Html.Attributes.href (FileStatus.fileUrl fileData.contentType fileData.fileHash) ]
               )
        )
        [ Email.Html.text (FileName.toString fileData.fileName)
        , Email.Html.text ("\n" ++ FileStatus.sizeToString fileData.fileSize)
        ]


fromNonemptyString : Time.Zone -> SeqDict userId { a | name : PersonName } -> NonemptyString -> Nonempty (RichText userId)
fromNonemptyString timezone users string =
    let
        source =
            String.Nonempty.toString string

        ( startIndex, startRevNodes ) =
            case extractBlockQuote source 0 of
                Just ( content, endIndex ) ->
                    ( endIndex, [ BlockQuote NoLeadingLineBreak (parseBlockQuoteContent timezone users content) ] )

                Nothing ->
                    case extractHeading source 0 of
                        Just ( level, content, endIndex ) ->
                            ( endIndex, [ Heading level NoLeadingLineBreak (parseHeadingContent timezone users content) ] )

                        Nothing ->
                            case extractBulletPoint starBulletMarker (parseBlockQuoteContent timezone users) source 0 of
                                Just bullet ->
                                    ( bullet.endIndex
                                    , bulletRevNodes (BulletPoint NoLeadingLineBreak bullet.items) bullet.trailing []
                                    )

                                Nothing ->
                                    ( 0, [] )

        result =
            parseLoop timezone source startIndex users [] "" startRevNodes
    in
    case List.Nonempty.fromList result.nodes of
        Just nonempty ->
            normalize nonempty

        Nothing ->
            Nonempty (normalTextFromNonempty string) []


parseBlockQuoteContent : Time.Zone -> SeqDict userId { a | name : PersonName } -> String -> List (RichText userId)
parseBlockQuoteContent timezone users content =
    case parseLoop timezone content 0 users [] "" [] |> .nodes |> List.Nonempty.fromList of
        Just nonempty ->
            normalize nonempty |> List.Nonempty.toList

        Nothing ->
            []


parseHeadingContent : Time.Zone -> SeqDict userId { a | name : PersonName } -> NonemptyString -> Nonempty (RichText userId)
parseHeadingContent timezone users content =
    case parseLoop timezone (String.Nonempty.toString content) 0 users [] "" [] |> .nodes |> List.Nonempty.fromList of
        Just nonempty ->
            normalize nonempty

        Nothing ->
            Nonempty (NormalText (String.Nonempty.head content) (String.Nonempty.tail content)) []


extractBlockQuote : String -> Int -> Maybe ( String, Int )
extractBlockQuote source index =
    case stringAtRange index 2 source of
        Just "> " ->
            let
                ( endIndex, content ) =
                    collectBlockQuoteLines source (index + 2)
            in
            Just ( content, endIndex )

        _ ->
            Nothing


extractHeading : String -> Int -> Maybe ( HeadingLevel, NonemptyString, Int )
extractHeading source index =
    case stringAtRange index 4 source of
        Just "### " ->
            collectHeadingLine H3 source (index + 4)

        _ ->
            case stringAtRange index 3 source of
                Just "## " ->
                    collectHeadingLine H2 source (index + 3)

                Just "-# " ->
                    collectHeadingLine Small source (index + 3)

                _ ->
                    case stringAtRange index 2 source of
                        Just "# " ->
                            collectHeadingLine H1 source (index + 2)

                        _ ->
                            Nothing


collectHeadingLine : HeadingLevel -> String -> Int -> Maybe ( HeadingLevel, NonemptyString, Int )
collectHeadingLine level source contentStart =
    let
        lineEnd =
            findLineEnd source contentStart
    in
    case String.slice contentStart lineEnd source |> String.Nonempty.fromString of
        Just nonempty ->
            Just ( level, nonempty, lineEnd )

        Nothing ->
            Nothing


collectBlockQuoteLines : String -> Int -> ( Int, String )
collectBlockQuoteLines source index =
    let
        lineEnd =
            findLineEnd source index

        line =
            String.slice index lineEnd source
    in
    case stringAtRange lineEnd 3 source of
        Just "\n> " ->
            let
                afterGt =
                    lineEnd + 3

                ( nextEnd, nextContent ) =
                    collectBlockQuoteLines source afterGt
            in
            ( nextEnd, line ++ "\n" ++ nextContent )

        _ ->
            ( lineEnd, line )


findLineEnd : String -> Int -> Int
findLineEnd source index =
    if index >= String.length source then
        index

    else if stringAt index source == Just "\n" then
        index

    else
        findLineEnd source (index + 1)


{-| Matches a bullet point marker ("\* ") at the given index, returning the marker length.
-}
starBulletMarker : String -> Int -> Maybe Int
starBulletMarker source index =
    if stringAtRange index 2 source == Just "* " then
        Just 2

    else
        Nothing


{-| Matches a Discord bullet point marker ("\* " or "- ") at the given index, returning the marker length.
-}
starOrDashBulletMarker : String -> Int -> Maybe Int
starOrDashBulletMarker source index =
    case stringAtRange index 2 source of
        Just "* " ->
            Just 2

        Just "- " ->
            Just 2

        _ ->
            Nothing


{-| Checks if the line that ended at `lineEnd` is followed by another bullet line ("\\n" then a marker).
Returns the separator text (e.g. "\\n\* ") and the index where the next line's content starts.
-}
bulletContinuation : (String -> Int -> Maybe Int) -> String -> Int -> Maybe ( String, Int )
bulletContinuation matchMarker source lineEnd =
    if stringAt lineEnd source == Just "\n" then
        case matchMarker source (lineEnd + 1) of
            Just markerLen ->
                Just ( String.slice lineEnd (lineEnd + 1 + markerLen) source, lineEnd + 1 + markerLen )

            Nothing ->
                Nothing

    else
        Nothing


collectBulletLines :
    (String -> Int -> Maybe Int)
    -> (String -> List (RichText userId))
    -> String
    -> Int
    -> String
    -> { items : List (List (RichText userId)), trailing : String, endIndex : Int }
collectBulletLines matchMarker parseContent source contentStart markerPrefix =
    let
        lineEnd =
            findLineEnd source contentStart

        nodes =
            parseContent (String.slice contentStart lineEnd source)
    in
    case bulletContinuation matchMarker source lineEnd of
        Just ( nextPrefix, nextContentStart ) ->
            let
                rest =
                    collectBulletLines matchMarker parseContent source nextContentStart nextPrefix
            in
            { items = nodes :: rest.items, trailing = rest.trailing, endIndex = rest.endIndex }

        Nothing ->
            if List.isEmpty nodes then
                -- An empty bullet item at the end of the list isn't treated as a bullet. Instead the
                -- marker (and the line break before it) is left as normal text.
                { items = [], trailing = markerPrefix, endIndex = lineEnd }

            else
                { items = [ nodes ], trailing = "", endIndex = lineEnd }


extractBulletPoint :
    (String -> Int -> Maybe Int)
    -> (String -> List (RichText userId))
    -> String
    -> Int
    -> Maybe { items : Nonempty (List (RichText userId)), trailing : String, endIndex : Int }
extractBulletPoint matchMarker parseContent source index =
    case matchMarker source index of
        Just markerLen ->
            let
                result =
                    collectBulletLines
                        matchMarker
                        parseContent
                        source
                        (index + markerLen)
                        (String.slice index (index + markerLen) source)
            in
            case List.Nonempty.fromList result.items of
                Just items ->
                    Just { items = items, trailing = result.trailing, endIndex = result.endIndex }

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


{-| Prepends a bullet point node (and any leftover trailing text) to the reversed node list.
-}
bulletRevNodes : RichText userId -> String -> List (RichText userId) -> List (RichText userId)
bulletRevNodes bulletNode trailing flushed =
    case String.Nonempty.fromString trailing of
        Just t ->
            NormalText (String.Nonempty.head t) (String.Nonempty.tail t) :: bulletNode :: flushed

        Nothing ->
            bulletNode :: flushed


{-| Applies a function to the contents of a single bullet item, preserving empty items.
-}
mapBulletItem : (Nonempty (RichText userId) -> Nonempty (RichText userId)) -> List (RichText userId) -> List (RichText userId)
mapBulletItem f item =
    case List.Nonempty.fromList item of
        Just nonempty ->
            f nonempty |> List.Nonempty.toList

        Nothing ->
            item


{-| Collects values from the contents of a single bullet item.
-}
bulletItemConcatMap : (Nonempty (RichText userId) -> List a) -> List (RichText userId) -> List a
bulletItemConcatMap f item =
    case List.Nonempty.fromList item of
        Just nonempty ->
            f nonempty

        Nothing ->
            []


normalize : Nonempty (RichText userId) -> Nonempty (RichText userId)
normalize nonempty =
    List.foldl
        (\richText nonempty2 ->
            case richText of
                NormalText char rest ->
                    case List.Nonempty.head nonempty2 of
                        NormalText previousChar previousRest ->
                            List.Nonempty.replaceHead
                                (NormalText previousChar (previousRest ++ String.cons char rest))
                                nonempty2

                        _ ->
                            List.Nonempty.cons richText nonempty2

                Italic a ->
                    List.Nonempty.cons (Italic (normalize a)) nonempty2

                Bold a ->
                    List.Nonempty.cons (Bold (normalize a)) nonempty2

                Underline a ->
                    List.Nonempty.cons (Underline (normalize a)) nonempty2

                UserMention _ ->
                    List.Nonempty.cons richText nonempty2

                Strikethrough a ->
                    List.Nonempty.cons (Strikethrough (normalize a)) nonempty2

                Spoiler a ->
                    List.Nonempty.cons (Spoiler (normalize a)) nonempty2

                BlockQuote hasLeadingLineBreak list ->
                    List.Nonempty.cons
                        (BlockQuote hasLeadingLineBreak
                            (case List.Nonempty.fromList list of
                                Just a ->
                                    normalize a |> List.Nonempty.toList

                                Nothing ->
                                    list
                            )
                        )
                        nonempty2

                Heading level hasLeadingLineBreak a ->
                    List.Nonempty.cons (Heading level hasLeadingLineBreak (normalize a)) nonempty2

                Hyperlink data ->
                    List.Nonempty.cons (Hyperlink data) nonempty2

                MarkdownLink alias url ->
                    List.Nonempty.cons (MarkdownLink alias url) nonempty2

                InlineCode char string ->
                    List.Nonempty.cons (InlineCode char string) nonempty2

                CodeBlock language string ->
                    List.Nonempty.cons (CodeBlock language string) nonempty2

                AttachedFile fileId ->
                    List.Nonempty.cons (AttachedFile fileId) nonempty2

                EscapedChar char ->
                    List.Nonempty.cons (EscapedChar char) nonempty2

                Sticker id ->
                    List.Nonempty.cons (Sticker id) nonempty2

                CustomEmoji id ->
                    List.Nonempty.cons (CustomEmoji id) nonempty2

                BulletPoint hasLeadingLineBreak items ->
                    List.Nonempty.cons
                        (BulletPoint hasLeadingLineBreak (List.Nonempty.map (mapBulletItem normalize) items))
                        nonempty2

                Timestamp time ->
                    List.Nonempty.cons (Timestamp time) nonempty2
        )
        (Nonempty
            (case List.Nonempty.head nonempty of
                Italic a ->
                    Italic (normalize a)

                UserMention id ->
                    UserMention id

                NormalText char string ->
                    NormalText char string

                Bold a ->
                    Bold (normalize a)

                Underline a ->
                    Underline (normalize a)

                Strikethrough a ->
                    Strikethrough (normalize a)

                Spoiler a ->
                    Spoiler (normalize a)

                BlockQuote hasLeadingLineBreak list ->
                    BlockQuote
                        hasLeadingLineBreak
                        (case List.Nonempty.fromList list of
                            Just a ->
                                normalize a |> List.Nonempty.toList

                            Nothing ->
                                list
                        )

                Heading level hasLeadingLineBreak a ->
                    Heading level hasLeadingLineBreak (normalize a)

                Hyperlink data ->
                    Hyperlink data

                MarkdownLink alias url ->
                    MarkdownLink alias url

                InlineCode char string ->
                    InlineCode char string

                CodeBlock language string ->
                    CodeBlock language string

                AttachedFile fileId ->
                    AttachedFile fileId

                EscapedChar char ->
                    EscapedChar char

                Sticker id ->
                    Sticker id

                CustomEmoji id ->
                    CustomEmoji id

                BulletPoint hasLeadingLineBreak items ->
                    BulletPoint hasLeadingLineBreak (List.Nonempty.map (mapBulletItem normalize) items)

                Timestamp time ->
                    Timestamp time
            )
            []
        )
        (List.Nonempty.tail nonempty)
        |> List.Nonempty.reverse


type Modifiers
    = IsBold
    | IsItalic
    | IsUnderlined
    | IsStrikethrough
    | IsSpoilered


modifierToSymbol : Modifiers -> NonemptyString
modifierToSymbol modifier =
    case modifier of
        IsBold ->
            NonemptyString '*' ""

        IsItalic ->
            NonemptyString '_' ""

        IsUnderlined ->
            NonemptyString '_' "_"

        IsStrikethrough ->
            NonemptyString '~' "~"

        IsSpoilered ->
            NonemptyString '|' "|"


charToEscaped : Dict String EscapedChar
charToEscaped =
    List.map (\escaped -> ( escapedCharToString escaped, escaped )) allEscapedChars |> Dict.fromList


{-| Discord takes the backslash off any character that isn't a letter, a digit or a space,
whether or not that character was going to be formatting: `\\_` reads as `_` even where there
was no italics to prevent. Reading only a handful of characters back this way left the rest
of the backslashes on show in at-chat, so a message at-chat had escaped on the way out came
home wearing them.

Which characters those are isn't documented anywhere Discord publishes; this is the rule the
markdown library its client is built on uses, and it matches what Discord does with the
characters at-chat escapes. `scripts/discord-markdown` is there to check it against a real
client when a new one comes up.

-}
isDiscordEscapable : String -> Bool
isDiscordEscapable text =
    case String.uncons text of
        Just ( char, "" ) ->
            not (Char.isAlphaNum char) && not (isWhitespaceChar char)

        _ ->
            False


{-| Text that looked like an address but turned out not to be one is taken in a single piece,
the same way at-chat's own parser takes it, so that both of them read `http://a.com_http://a.com`
as one piece of text rather than one parser finding a link in the middle of it. Taking it in
one piece means the loop never sees the backslashes inside it, so they come off here.
-}
unescapeDiscordText : String -> { text : String, consumed : Int }
unescapeDiscordText text =
    String.foldl
        (\char ( afterBackslash, acc ) ->
            if afterBackslash then
                if isDiscordEscapable (String.fromChar char) then
                    ( False, char :: acc )

                else
                    ( False, char :: '\\' :: acc )

            else if char == '\\' then
                ( True, acc )

            else
                ( False, char :: acc )
        )
        ( False, [] )
        text
        |> (\( afterBackslash, acc ) ->
                { text = List.reverse acc |> String.fromList
                , consumed =
                    -- A backslash at the very end of the run is escaping the character after
                    -- it, which is outside the run, so it's left where the loop will find it
                    String.length text
                        - (if afterBackslash then
                            1

                           else
                            0
                          )
                }
           )


isWhitespaceChar : Char -> Bool
isWhitespaceChar char =
    char == ' ' || char == '\n' || char == '\u{000D}' || char == '\t'


{-| Without a special case the parser reads the backslash as escaping the first underscore and
then the second underscore as the start of italics, so the shrug loses its arm. It's common
enough that it's worth parsing as escaped characters instead, so it always shows up exactly as
it was typed.
-}
shrugEmoticon : String
shrugEmoticon =
    "¯\\_(ツ)_/¯"


attachedFilePrefix : String
attachedFilePrefix =
    "[!"


attachedFileSuffix : String
attachedFileSuffix =
    "]"


flushText : String -> List (RichText userId) -> List (RichText userId)
flushText text revNodes =
    case String.uncons text of
        Just ( char, rest ) ->
            NormalText char rest :: revNodes

        Nothing ->
            revNodes


finalizeResult :
    (modifier -> NonemptyString)
    -> String
    -> List (RichText userId)
    -> List modifier
    -> Int
    -> { nodes : List (RichText userId), nextIndex : Int }
finalizeResult modifierToString accText revNodes modifiers index =
    let
        flushed =
            flushText accText revNodes

        finalNodes =
            List.reverse flushed
    in
    { nodes =
        case modifiers of
            head :: _ ->
                let
                    (NonemptyString char rest) =
                        modifierToString head
                in
                NormalText char rest :: finalNodes

            [] ->
                finalNodes
    , nextIndex = index
    }


closeModifier : Int -> String -> List (RichText userId) -> (Nonempty (RichText userId) -> RichText userId) -> NonemptyString -> { nodes : List (RichText userId), nextIndex : Int }
closeModifier afterSymbol accText revNodes container symbol =
    let
        flushed =
            flushText accText revNodes

        finalNodes =
            List.reverse flushed
    in
    case List.Nonempty.fromList finalNodes of
        Just nonempty ->
            { nodes = [ container nonempty ], nextIndex = afterSymbol }

        Nothing ->
            { nodes = [ NormalText (String.Nonempty.head symbol) (String.Nonempty.tail symbol) ]
            , nextIndex = afterSymbol
            }


parseInner : Time.Zone -> String -> Int -> SeqDict userId { a | name : PersonName } -> List Modifiers -> { nodes : List (RichText userId), nextIndex : Int }
parseInner timezone source index users modifiers =
    parseLoop timezone source index users modifiers "" []


stringAt : Int -> String -> Maybe String
stringAt index text =
    if index < String.length text then
        String.slice index (index + 1) text |> Just

    else
        Nothing


stringAtRange : Int -> Int -> String -> Maybe String
stringAtRange index count text =
    if index + count <= String.length text && count >= 0 then
        String.slice index (index + count) text |> Just

    else
        Nothing


parseStickerId : Int -> String -> ( Int, Maybe (Id StickerId) )
parseStickerId index source =
    case stringAt index source of
        Just char ->
            case char of
                "\u{200B}" ->
                    if stringAtRange (index + 1) 2 source == Just "\n\n" then
                        ( index + 3, Just (Id.fromInt 0) )

                    else
                        ( index + 1, Nothing )

                "\u{200C}" ->
                    parseStickerIdHelper 1 (index + 1) source

                "\u{200D}" ->
                    parseStickerIdHelper 2 (index + 1) source

                "\u{2060}" ->
                    parseStickerIdHelper 3 (index + 1) source

                _ ->
                    ( index, Nothing )

        Nothing ->
            ( index, Nothing )


parseStickerIdHelper : Int -> Int -> String -> ( Int, Maybe (Id StickerId) )
parseStickerIdHelper id index source =
    case stringAt index source of
        Just char ->
            case char of
                "\u{200B}" ->
                    parseStickerIdHelper (4 * id) (index + 1) source

                "\u{200C}" ->
                    parseStickerIdHelper (1 + 4 * id) (index + 1) source

                "\u{200D}" ->
                    parseStickerIdHelper (2 + 4 * id) (index + 1) source

                "\u{2060}" ->
                    parseStickerIdHelper (3 + 4 * id) (index + 1) source

                "\n" ->
                    case ( stringAt (index + 1) source, id <= Basics.Extra.maxSafeInteger ) of
                        ( Just "\n", True ) ->
                            ( index + 2, Just (Id.fromInt id) )

                        _ ->
                            ( index + 1, Nothing )

                _ ->
                    ( index, Nothing )

        Nothing ->
            ( index, Nothing )


parseCustomEmojiId : Int -> String -> ( Int, Maybe (Id CustomEmojiId) )
parseCustomEmojiId index source =
    case stringAt index source of
        Just char ->
            case char of
                "\u{200B}" ->
                    if stringAt (index + 1) source == Just "\u{FEFF}" then
                        ( index + 2, Just (Id.fromInt 0) )

                    else
                        ( index + 1, Nothing )

                "\u{200C}" ->
                    parseCustomEmojiIdHelper 1 (index + 1) source

                "\u{200D}" ->
                    parseCustomEmojiIdHelper 2 (index + 1) source

                "\u{2060}" ->
                    parseCustomEmojiIdHelper 3 (index + 1) source

                _ ->
                    ( index, Nothing )

        Nothing ->
            ( index, Nothing )


parseCustomEmojiIdHelper : Int -> Int -> String -> ( Int, Maybe (Id CustomEmojiId) )
parseCustomEmojiIdHelper id index source =
    case stringAt index source of
        Just char ->
            case char of
                "\u{200B}" ->
                    parseCustomEmojiIdHelper (4 * id) (index + 1) source

                "\u{200C}" ->
                    parseCustomEmojiIdHelper (1 + 4 * id) (index + 1) source

                "\u{200D}" ->
                    parseCustomEmojiIdHelper (2 + 4 * id) (index + 1) source

                "\u{2060}" ->
                    parseCustomEmojiIdHelper (3 + 4 * id) (index + 1) source

                "\u{FEFF}" ->
                    ( index + 1, Just (Id.fromInt id) )

                _ ->
                    ( index, Nothing )

        Nothing ->
            ( index, Nothing )


stringToStickersAndCustomEmojis : String -> List ( Range, Maybe () )
stringToStickersAndCustomEmojis text =
    let
        stickers2 : List ( Range, Maybe () )
        stickers2 =
            String.indexes "\n\u{200B}" text
                ++ String.indexes "\n\u{200C}" text
                ++ String.indexes "\n\u{200D}" text
                ++ String.indexes "\n\u{2060}" text
                |> List.foldl
                    (\index shouldRemove ->
                        let
                            ( endIndex, stickerId ) =
                                parseStickerId (index + 1) text
                        in
                        ( { start = index, end = endIndex }, Maybe.map (\_ -> ()) stickerId ) :: shouldRemove
                    )
                    []

        customEmojis2 : List ( Range, Maybe () )
        customEmojis2 =
            String.indexes "❓\u{200B}" text
                ++ String.indexes "❓\u{200C}" text
                ++ String.indexes "❓\u{200D}" text
                ++ String.indexes "❓\u{2060}" text
                |> List.foldl
                    (\index shouldRemove ->
                        let
                            ( endIndex, customEmojiId ) =
                                parseCustomEmojiId (index + 1) text
                        in
                        ( { start = index, end = endIndex }, Maybe.map (\_ -> ()) customEmojiId ) :: shouldRemove
                    )
                    []
    in
    stickers2 ++ customEmojis2 |> List.sortBy (\( range, _ ) -> -range.start)


parseLoop :
    Time.Zone
    -> String
    -> Int
    -> SeqDict userId { a | name : PersonName }
    -> List Modifiers
    -> String
    -> List (RichText userId)
    -> { nodes : List (RichText userId), nextIndex : Int }
parseLoop timezone source index users modifiers accText revNodes =
    if index >= String.length source then
        finalizeResult modifierToSymbol accText revNodes modifiers index

    else
        case String.slice index (index + 1) source of
            "❓" ->
                case parseCustomEmojiId (index + 1) source of
                    ( index2, Just customEmojiId ) ->
                        parseLoop timezone source index2 users modifiers "" (CustomEmoji customEmojiId :: flushText accText revNodes)

                    ( _, Nothing ) ->
                        parseLoop timezone source (index + 1) users modifiers (accText ++ "❓") revNodes

            "\n" ->
                if List.isEmpty modifiers then
                    case extractBlockQuote source (index + 1) of
                        Just ( content, endIndex ) ->
                            parseLoop timezone
                                source
                                endIndex
                                users
                                modifiers
                                ""
                                (BlockQuote
                                    HasLeadingLineBreak
                                    (parseBlockQuoteContent timezone users content)
                                    :: flushText accText revNodes
                                )

                        Nothing ->
                            case extractHeading source (index + 1) of
                                Just ( level, content, endIndex ) ->
                                    parseLoop timezone
                                        source
                                        endIndex
                                        users
                                        modifiers
                                        ""
                                        (Heading
                                            level
                                            HasLeadingLineBreak
                                            (parseHeadingContent timezone users content)
                                            :: flushText accText revNodes
                                        )

                                Nothing ->
                                    case extractBulletPoint starBulletMarker (parseBlockQuoteContent timezone users) source (index + 1) of
                                        Just bullet ->
                                            parseLoop timezone
                                                source
                                                bullet.endIndex
                                                users
                                                modifiers
                                                ""
                                                (bulletRevNodes
                                                    (BulletPoint HasLeadingLineBreak bullet.items)
                                                    bullet.trailing
                                                    (flushText accText revNodes)
                                                )

                                        Nothing ->
                                            case parseStickerId (index + 1) source of
                                                ( index2, Just stickerId ) ->
                                                    parseLoop timezone source index2 users modifiers "" (Sticker stickerId :: flushText accText revNodes)

                                                ( _, Nothing ) ->
                                                    parseLoop timezone source (index + 1) users modifiers (accText ++ "\n") revNodes

                else
                    -- Line breaks should terminate any open modifiers
                    finalizeResult modifierToSymbol accText revNodes modifiers index

            "¯" ->
                if String.slice index (index + String.length shrugEmoticon) source == shrugEmoticon then
                    parseLoop timezone
                        source
                        (index + String.length shrugEmoticon)
                        users
                        modifiers
                        ""
                        (NormalText '¯' "\\_(ツ)_/¯" :: flushText accText revNodes)

                else
                    parseLoop timezone source (index + 1) users modifiers (accText ++ "¯") revNodes

            "\\" ->
                let
                    afterBackslash =
                        index + 1
                in
                case stringAt afterBackslash source of
                    Just nextChar ->
                        case Dict.get nextChar charToEscaped of
                            Just escaped ->
                                parseLoop timezone source (afterBackslash + 1) users modifiers "" (EscapedChar escaped :: flushText accText revNodes)

                            Nothing ->
                                -- The backslash isn't escaping anything, so only it is taken and
                                -- what follows goes back through the loop to be read the way it
                                -- would have been without it. Taking that character too meant
                                -- `\http://a.com` never reached the code that spots an address,
                                -- so a backslash in front of one quietly stopped it being a link.
                                parseLoop timezone source afterBackslash users modifiers (accText ++ "\\") revNodes

                    Nothing ->
                        parseLoop timezone source afterBackslash users modifiers (accText ++ "\\") revNodes

            "@" ->
                let
                    afterAt =
                        index + 1

                    remaining =
                        String.slice afterAt (String.length source) source
                in
                case tryMatchUser users remaining of
                    Just ( userId, matchLen ) ->
                        parseLoop timezone source (afterAt + matchLen) users modifiers "" (UserMention userId :: flushText accText revNodes)

                    Nothing ->
                        parseLoop timezone source afterAt users modifiers (accText ++ "@") revNodes

            "*" ->
                let
                    afterSymbol =
                        index + 1
                in
                if List.head modifiers == Just IsBold then
                    closeModifier afterSymbol accText revNodes Bold (modifierToSymbol IsBold)

                else if List.member IsBold modifiers then
                    finalizeResult modifierToSymbol accText revNodes modifiers index

                else
                    let
                        nextChar =
                            String.slice afterSymbol (afterSymbol + 1) source
                    in
                    if nextChar == "*" || nextChar == " " then
                        parseLoop timezone source afterSymbol users modifiers (accText ++ "*") revNodes

                    else
                        let
                            flushed =
                                flushText accText revNodes

                            inner =
                                parseInner timezone source afterSymbol users (IsBold :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        parseLoop timezone source inner.nextIndex users modifiers "" newRevNodes

            "_" ->
                if String.slice index (index + 4) source == "____" then
                    parseLoop timezone source (index + 4) users modifiers (accText ++ "____") revNodes

                else if String.slice index (index + 2) source == "__" then
                    let
                        afterSymbol =
                            index + 2
                    in
                    if List.head modifiers == Just IsUnderlined then
                        closeModifier afterSymbol accText revNodes Underline (modifierToSymbol IsUnderlined)

                    else if List.member IsUnderlined modifiers then
                        finalizeResult modifierToSymbol accText revNodes modifiers index

                    else
                        let
                            flushed =
                                flushText accText revNodes

                            inner =
                                parseInner timezone source afterSymbol users (IsUnderlined :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        parseLoop timezone source inner.nextIndex users modifiers "" newRevNodes

                else
                    let
                        afterSymbol =
                            index + 1
                    in
                    if List.head modifiers == Just IsItalic then
                        closeModifier afterSymbol accText revNodes Italic (modifierToSymbol IsItalic)

                    else if List.member IsItalic modifiers then
                        finalizeResult modifierToSymbol accText revNodes modifiers index

                    else
                        let
                            flushed =
                                flushText accText revNodes

                            inner =
                                parseInner timezone source afterSymbol users (IsItalic :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        parseLoop timezone source inner.nextIndex users modifiers "" newRevNodes

            "~" ->
                if (List.head modifiers /= Just IsStrikethrough) && String.slice index (index + 4) source == "~~~~" then
                    parseLoop timezone source (index + 4) users modifiers (accText ++ "~~~~") revNodes

                else if String.slice index (index + 2) source == "~~" then
                    let
                        afterSymbol =
                            index + 2
                    in
                    if List.head modifiers == Just IsStrikethrough then
                        closeModifier afterSymbol accText revNodes Strikethrough (modifierToSymbol IsStrikethrough)

                    else if List.member IsStrikethrough modifiers then
                        finalizeResult modifierToSymbol accText revNodes modifiers index

                    else
                        let
                            flushed =
                                flushText accText revNodes

                            inner =
                                parseInner timezone source afterSymbol users (IsStrikethrough :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        parseLoop timezone source inner.nextIndex users modifiers "" newRevNodes

                else
                    parseLoop timezone source (index + 1) users modifiers (accText ++ "~") revNodes

            "|" ->
                if (List.head modifiers /= Just IsSpoilered) && String.slice index (index + 4) source == "||||" then
                    parseLoop timezone source (index + 4) users modifiers (accText ++ "||||") revNodes

                else if String.slice index (index + 2) source == "||" then
                    let
                        afterSymbol =
                            index + 2
                    in
                    if List.head modifiers == Just IsSpoilered then
                        closeModifier afterSymbol accText revNodes Spoiler (modifierToSymbol IsSpoilered)

                    else if List.member IsSpoilered modifiers then
                        finalizeResult modifierToSymbol accText revNodes modifiers index

                    else
                        let
                            flushed =
                                flushText accText revNodes

                            inner =
                                parseInner timezone source afterSymbol users (IsSpoilered :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        parseLoop timezone source inner.nextIndex users modifiers "" newRevNodes

                else
                    parseLoop timezone source (index + 1) users modifiers (accText ++ "|") revNodes

            "`" ->
                case ( stringAtRange index 3 source, findSubstring source (index + 3) "```" ) of
                    ( Just "```", Just closeIndex ) ->
                        let
                            content =
                                String.slice (index + 3) closeIndex source

                            ( language, codeContent ) =
                                parseCodeBlockContent content
                        in
                        case String.Nonempty.fromString codeContent of
                            Just _ ->
                                parseLoop timezone source (closeIndex + 3) users modifiers "" (CodeBlock language codeContent :: flushText accText revNodes)

                            Nothing ->
                                parseLoop timezone source (closeIndex + 3) users modifiers (accText ++ "``````") revNodes

                    _ ->
                        case findSingleBacktick source (index + 1) of
                            Just closeIndex ->
                                let
                                    content =
                                        String.slice (index + 1) closeIndex source
                                in
                                case ( String.Nonempty.fromString content, String.contains "\n" content ) of
                                    ( Just a, False ) ->
                                        parseLoop timezone source (closeIndex + 1) users modifiers "" (InlineCode (String.Nonempty.head a) (String.Nonempty.tail a) :: flushText accText revNodes)

                                    _ ->
                                        parseLoop timezone source (index + 1) users modifiers (accText ++ "`") revNodes

                            Nothing ->
                                parseLoop timezone source (index + 1) users modifiers (accText ++ "`") revNodes

            "h" ->
                case parseUrlBody False modifierToSymbol modifiers index source of
                    Ok url ->
                        parseLoop timezone
                            source
                            (index + String.length (Url.toString url))
                            users
                            modifiers
                            ""
                            (Hyperlink url :: flushText accText revNodes)

                    Err errText ->
                        parseLoop timezone
                            source
                            (index + String.length errText)
                            users
                            modifiers
                            (accText ++ errText)
                            revNodes

            "[" ->
                if String.slice index (index + 2) source == "[!" then
                    case parseFileId source (index + 2) of
                        Just ( fileId, nextIndex ) ->
                            parseLoop timezone source nextIndex users modifiers "" (AttachedFile (Id.fromInt fileId) :: flushText accText revNodes)

                        Nothing ->
                            parseLoop timezone source (index + 1) users modifiers (accText ++ "[") revNodes

                else
                    case parseMarkdownLink False source (index + 1) of
                        Just ( alias, url, nextIndex ) ->
                            parseLoop timezone source nextIndex users modifiers "" (MarkdownLink alias url :: flushText accText revNodes)

                        Nothing ->
                            parseLoop timezone source (index + 1) users modifiers (accText ++ "[") revNodes

            _ ->
                -- A timestamp starts with a month name rather than a symbol, so unlike
                -- everything above it there's no single character to match on. skipNormalChars
                -- stops on the letters the twelve months start with, which is what brings the
                -- loop back here often enough for this to get a look at them.
                case tryParseTimestamp timezone source index of
                    Just ( time, timeEndIndex ) ->
                        parseLoop timezone source timeEndIndex users modifiers "" (Timestamp time :: flushText accText revNodes)

                    Nothing ->
                        let
                            nextIndex =
                                skipNormalChars source (index + 1)
                        in
                        parseLoop timezone source nextIndex users modifiers (accText ++ String.slice index nextIndex source) revNodes


{-| at-chat's own timestamp syntax, which is just how a timestamp reads:
`August 6, 2026 at 10:50`. Unlike Discord's `<t:1786013400:f>` this is what the message input
shows while the message is being written, so it has to be text a person would be happy
looking at.

The date and time are in `timezone`, and timestamps are only kept to the minute, so the
moment this names is the only one that writes itself back out as this exact string. That
makes reading it the exact inverse of `dateAndTimeToString`, which is what lets a message be
turned into text for editing and read back without its timestamps drifting.

A date that doesn't exist (`February 31`) or a time the clocks skipped over is left as text,
since writing it back out would produce something different from what was read.

-}
tryParseTimestamp : Time.Zone -> String -> Int -> Maybe ( TimeInMinutes, Int )
tryParseTimestamp timezone source index =
    let
        len : Int
        len =
            String.length source
    in
    case tryParseMonth source index of
        Just ( month, afterMonth ) ->
            let
                dayEnd : Int
                dayEnd =
                    skipDigits source afterMonth len

                yearStart : Int
                yearStart =
                    dayEnd + 2

                yearEnd : Int
                yearEnd =
                    skipDigits source yearStart len

                hourStart : Int
                hourStart =
                    yearEnd + 4
            in
            if
                (dayEnd > afterMonth)
                    && (String.slice dayEnd yearStart source == ", ")
                    && (yearEnd > yearStart)
                    && (String.slice yearEnd hourStart source == " at ")
                    && (stringAt (hourStart + 2) source == Just ":")
                    && (hourStart + 5 <= len)
            then
                case
                    ( ( String.toInt (String.slice afterMonth dayEnd source)
                      , String.toInt (String.slice yearStart yearEnd source)
                      )
                    , ( String.toInt (String.slice hourStart (hourStart + 2) source)
                      , String.toInt (String.slice (hourStart + 3) (hourStart + 5) source)
                      )
                    )
                of
                    ( ( Just day, Just year ), ( Just hour, Just minute ) ) ->
                        let
                            endIndex : Int
                            endIndex =
                                hourStart + 5

                            time : TimeInMinutes
                            time =
                                TimeInMinutes.fromDateAndTime
                                    timezone
                                    { year = year, month = month, day = day, hour = hour, minute = minute }
                        in
                        -- Writing the result back out and checking it still says the same thing
                        -- is what makes this the exact inverse of dateAndTimeToString. It's also
                        -- what rejects February 31, an hour the clocks skipped over, and a `06`
                        -- where the day is written without a leading zero: all of those name a
                        -- moment that would come back out as different text, and the message
                        -- input lines its formatting up with the text it's given, so a timestamp
                        -- of a different length there would shift everything after it.
                        if dateAndTimeToString timezone time == String.slice index endIndex source then
                            Just ( time, endIndex )

                        else
                            Nothing

                    _ ->
                        Nothing

            else
                Nothing

        Nothing ->
            Nothing


{-| The month name at `index`, along with the index just past it. No month name is the start
of another one, so the first that fits is the only one that can.
-}
tryParseMonth : String -> Int -> Maybe ( Time.Month, Int )
tryParseMonth source index =
    List.filterMap
        (\month ->
            let
                name : String
                name =
                    MyUi.monthToString month

                afterMonth : Int
                afterMonth =
                    index + String.length name + 1
            in
            if String.slice index afterMonth source == name ++ " " then
                Just ( month, afterMonth )

            else
                Nothing
        )
        MyUi.allMonths
        |> List.head


tryMatchUser : SeqDict userId { a | name : PersonName } -> String -> Maybe ( userId, Int )
tryMatchUser users remaining =
    SeqDict.toList users
        |> List.sortBy (\( _, user ) -> PersonName.toString user.name |> String.length |> negate)
        |> List.filterMap
            (\( userId, user ) ->
                let
                    name =
                        PersonName.toString user.name
                in
                if String.startsWith name remaining then
                    Just ( userId, String.length name )

                else
                    Nothing
            )
        |> List.head


parseUrlBody : Bool -> (modifier -> NonemptyString) -> List modifier -> Int -> String -> Result String Url
parseUrlBody startedWithAngleBracket modifierToString modifiers index source =
    let
        protocolResult =
            if String.slice index (index + 8) source == "https://" then
                Ok ( Https, index + 8 )

            else if String.slice index (index + 7) source == "http://" then
                Ok ( Http, index + 7 )

            else
                Err ()
    in
    case protocolResult of
        Ok ( protocol, protocolEnd ) ->
            let
                urlEnd =
                    skipUrlChars source protocolEnd (String.length source)

                urlBody =
                    String.slice protocolEnd urlEnd source

                urlBodyLen =
                    String.length urlBody

                modifierChars =
                    List.map (\modifier -> modifierToString modifier |> String.Nonempty.head) modifiers |> Set.fromList

                ( openParenCount, closeParenCount ) =
                    String.foldl
                        (\char ( opens, closes ) ->
                            if char == '(' then
                                ( opens + 1, closes )

                            else if char == ')' then
                                ( opens, closes + 1 )

                            else
                                ( opens, closes )
                        )
                        ( 0, 0 )
                        urlBody

                -- A url containing ( keeps trailing ) instead of treating it as surrounding punctuation, unless the url itself is wrapped in parens, in which case only the surplus ) is trimmed
                allowedParenTrims =
                    if openParenCount == 0 then
                        closeParenCount

                    else if String.slice (index - 1) index source == "(" then
                        max 0 (closeParenCount - openParenCount)

                    else
                        0

                ( trimIdx, _, _ ) =
                    String.foldr
                        (\char ( idx, parenTrims, stop ) ->
                            if stop then
                                ( idx, parenTrims, True )

                            else if char == ')' then
                                if parenTrims > 0 then
                                    ( idx - 1, parenTrims - 1, False )

                                else
                                    ( idx, parenTrims, True )

                            else if char == '.' || char == ']' || char == ',' || char == '"' || char == ':' || Set.member char modifierChars then
                                ( idx - 1, parenTrims, False )

                            else if startedWithAngleBracket && char == '>' then
                                ( idx - 1, parenTrims, True )

                            else
                                ( idx, parenTrims, True )
                        )
                        ( urlBodyLen, allowedParenTrims, False )
                        urlBody

                protocolStr =
                    case protocol of
                        Http ->
                            "http://"

                        Https ->
                            "https://"

                urlText =
                    protocolStr ++ String.slice 0 trimIdx urlBody
            in
            case Url.fromString urlText of
                Just url ->
                    let
                        url2 =
                            { url | protocol = protocol }

                        urlNoPath =
                            { url2 | path = "" }
                    in
                    -- This is a hack to get the url decode to exactly match the user's input
                    -- Otherwise what the user is typing will get out of sync in the case they type http://google.com?query and it gets decoded to http://google.com/?query
                    if Url.toString urlNoPath == urlText then
                        Ok urlNoPath

                    else
                        Ok url2

                Nothing ->
                    Err urlText

        Err () ->
            Err "h"


skipUrlChars : String -> Int -> Int -> Int
skipUrlChars source index sourceLength =
    if index >= sourceLength then
        index

    else
        let
            c =
                String.slice index (index + 1) source
        in
        if c == " " || c == "\n" || c == "\t" || c == "<" || c == "|" then
            index

        else
            skipUrlChars source (index + 1) sourceLength


parseCodeBlockContent : String -> ( Language, String )
parseCodeBlockContent text =
    case String.split "\n" text of
        [ single ] ->
            ( NoLanguage, single )

        head :: rest ->
            if String.contains " " head then
                ( NoLanguage, text )

            else
                case String.Nonempty.fromString head of
                    Just nonempty ->
                        let
                            rest2 =
                                String.join "\n" rest
                        in
                        if String.isEmpty (String.trim rest2) then
                            ( NoLanguage, text )

                        else
                            ( Language nonempty, rest2 )

                    Nothing ->
                        ( NoLanguage, text )

        [] ->
            ( NoLanguage, "" )


findSubstring : String -> Int -> String -> Maybe Int
findSubstring source index target =
    let
        targetLen =
            String.length target
    in
    if index + targetLen > String.length source then
        Nothing

    else if String.slice index (index + targetLen) source == target then
        Just index

    else
        findSubstring source (index + 1) target


findSingleBacktick : String -> Int -> Maybe Int
findSingleBacktick source index =
    if index >= String.length source then
        Nothing

    else if String.slice index (index + 1) source == "`" then
        Just index

    else
        findSingleBacktick source (index + 1)


parseMarkdownLink : Bool -> String -> Int -> Maybe ( NonemptyString, Url, Int )
parseMarkdownLink isDiscord source index =
    let
        len =
            String.length source
    in
    case findChar source index len ']' of
        Just closeBracket ->
            let
                alias =
                    String.slice index closeBracket source

                afterBracket =
                    closeBracket + 1
            in
            if String.contains "[" alias then
                Nothing

            else if afterBracket < len && String.slice afterBracket (afterBracket + 1) source == "(" then
                case findChar source (afterBracket + 1) len ')' of
                    Just closeParen ->
                        let
                            urlText =
                                String.slice (afterBracket + 1) closeParen source
                                    |> (if isDiscord then
                                            String.trim

                                        else
                                            identity
                                       )
                        in
                        case ( String.Nonempty.fromString alias, Url.fromString urlText ) of
                            ( Just nonemptyAlias, Just url ) ->
                                let
                                    urlNoPath =
                                        { url | path = "" }
                                in
                                if Url.toString urlNoPath == urlText then
                                    Just ( nonemptyAlias, urlNoPath, closeParen + 1 )

                                else
                                    Just ( nonemptyAlias, url, closeParen + 1 )

                            _ ->
                                Nothing

                    Nothing ->
                        Nothing

            else
                Nothing

        Nothing ->
            Nothing


findChar : String -> Int -> Int -> Char -> Maybe Int
findChar source index len target =
    if index >= len then
        Nothing

    else if String.slice index (index + 1) source == String.fromChar target then
        Just index

    else
        findChar source (index + 1) len target


parseFileId : String -> Int -> Maybe ( Int, Int )
parseFileId source index =
    let
        len =
            String.length source

        digitEnd =
            skipDigits source index len
    in
    if digitEnd > index && digitEnd < len && String.slice digitEnd (digitEnd + 1) source == "]" then
        case String.toInt (String.slice index digitEnd source) of
            Just n ->
                Just ( n, digitEnd + 1 )

            Nothing ->
                Nothing

    else
        Nothing


skipDigits : String -> Int -> Int -> Int
skipDigits source index len =
    if index >= len then
        index

    else
        let
            c =
                String.slice index (index + 1) source
        in
        if c >= "0" && c <= "9" then
            skipDigits source (index + 1) len

        else
            index


skipNormalChars : String -> Int -> Int
skipNormalChars source index =
    if index >= String.length source then
        index

    else
        let
            c =
                String.slice index (index + 1) source
        in
        if c == "[" || c == "@" || c == "h" || c == "`" || c == "\\" || c == "*" || c == "_" || c == "~" || c == "|" || c == "\n" || c == "❓" || c == "¯" || isMonthStart c then
            index

        else
            skipNormalChars source (index + 1)


{-| The letters the twelve month names start with. A timestamp begins with one of these
rather than a symbol, so stopping here is what gets the parser back to a position where it
can check whether a timestamp follows.
-}
isMonthStart : String -> Bool
isMonthStart c =
    c == "J" || c == "F" || c == "M" || c == "A" || c == "S" || c == "O" || c == "N" || c == "D"


mentionsUser : Nonempty (RichText userId) -> SeqSet userId
mentionsUser nonempty =
    mentionsUserHelper SeqSet.empty nonempty


mentionsUserHelper : SeqSet userId -> Nonempty (RichText userId) -> SeqSet userId
mentionsUserHelper set nonempty =
    List.Nonempty.foldl
        (\richText set2 ->
            case richText of
                NormalText _ _ ->
                    set2

                UserMention mentionedUser ->
                    SeqSet.insert mentionedUser set2

                Bold nonempty2 ->
                    mentionsUserHelper set2 nonempty2

                Italic nonempty2 ->
                    mentionsUserHelper set2 nonempty2

                Underline nonempty2 ->
                    mentionsUserHelper set2 nonempty2

                Strikethrough nonempty2 ->
                    mentionsUserHelper set2 nonempty2

                Spoiler nonempty2 ->
                    mentionsUserHelper set2 nonempty2

                BlockQuote _ list ->
                    List.Nonempty.fromList list |> Maybe.map (mentionsUserHelper set2) |> Maybe.withDefault set2

                Heading _ _ nonempty2 ->
                    mentionsUserHelper set2 nonempty2

                Hyperlink _ ->
                    set2

                MarkdownLink _ _ ->
                    set2

                InlineCode _ _ ->
                    set2

                CodeBlock _ _ ->
                    set2

                AttachedFile _ ->
                    set2

                EscapedChar _ ->
                    set2

                Sticker _ ->
                    set2

                CustomEmoji _ ->
                    set2

                BulletPoint _ items ->
                    List.foldl
                        (\item set3 ->
                            case List.Nonempty.fromList item of
                                Just nonempty3 ->
                                    mentionsUserHelper set3 nonempty3

                                Nothing ->
                                    set3
                        )
                        set2
                        (List.Nonempty.toList items)

                Timestamp _ ->
                    set2
        )
        set
        nonempty


{-| OpaqueVariants
-}
type Domain
    = Domain String


urlToDomain : Url -> Domain
urlToDomain data =
    Domain data.host


domainToString : Domain -> String
domainToString (Domain domain) =
    domain


type ShowLargeContent
    = ShowLargeContent Int
    | NoLargeContent


hasLargeContent : Nonempty (RichText userId) -> Bool
hasLargeContent richText =
    List.Nonempty.any
        (\richText2 ->
            case richText2 of
                Bold a ->
                    hasLargeContent a

                UserMention _ ->
                    False

                NormalText _ _ ->
                    False

                Italic a ->
                    hasLargeContent a

                Underline a ->
                    hasLargeContent a

                Strikethrough a ->
                    hasLargeContent a

                Spoiler a ->
                    hasLargeContent a

                BlockQuote _ _ ->
                    True

                Heading _ _ a ->
                    hasLargeContent a

                Hyperlink _ ->
                    False

                MarkdownLink _ _ ->
                    False

                InlineCode _ _ ->
                    False

                CodeBlock _ _ ->
                    True

                AttachedFile _ ->
                    True

                EscapedChar _ ->
                    False

                Sticker _ ->
                    True

                CustomEmoji _ ->
                    False

                BulletPoint _ a ->
                    List.Nonempty.any
                        (\list ->
                            case List.Nonempty.fromList list of
                                Just nonempty ->
                                    hasLargeContent nonempty

                                Nothing ->
                                    False
                        )
                        a

                Timestamp _ ->
                    False
        )
        richText


view :
    HtmlId
    -> Int
    -> (Url -> msg)
    -> (Int -> msg)
    -> (PressedImageData -> msg)
    -> Config a userId
    -> Array Embed
    -> Nonempty (RichText userId)
    -> List (Html msg)
view htmlIdPrefix containerWidth onPressLink onPressSpoiler onPressImage config embeds nonempty =
    viewHelper
        False
        (ShowLargeContent containerWidth)
        (Just ( htmlIdPrefix, onPressSpoiler ))
        (Just onPressImage)
        onPressLink
        0
        { spoiler = False, underline = False, italic = False, bold = False, strikethrough = False }
        config
        embeds
        0
        nonempty
        |> (\( _, _, a ) -> a)


preview : (Url -> msg) -> PreviewConfig a userId -> Nonempty (RichText userId) -> List (Html msg)
preview onPressLink config nonempty =
    viewHelper
        False
        NoLargeContent
        Nothing
        Nothing
        onPressLink
        0
        { spoiler = False, underline = False, italic = False, bold = False, strikethrough = False }
        { domainWhitelist = config.domainWhitelist
        , revealedSpoilers = config.revealedSpoilers
        , users = config.users
        , attachedFiles = config.attachedFiles
        , stickers = SeqDict.empty
        , customEmojis = config.customEmojis
        , animationMode = Sticker.LoopAFewTimesOnLoad
        , timezone = config.timezone
        , time = config.time
        , drawings = SeqDict.empty
        , embedDrawings = SeqDict.empty
        , drawingUserColor = \_ -> UserColor.default
        , isSelectingAnchor = False
        , -- Previews replace code blocks with a placeholder, so no ascii art is drawn here
          devicePixelRatio = 1
        , isHovered = False
        }
        Array.empty
        0
        nonempty
        |> (\( _, _, a ) -> a)


type alias Config a userId =
    { domainWhitelist : SeqSet Domain
    , revealedSpoilers : SeqSet Int
    , users : SeqDict userId { a | name : PersonName }
    , attachedFiles : SeqDict (Id FileId) FileData
    , stickers : SeqDict (Id StickerId) StickerData
    , customEmojis : SeqDict (Id CustomEmojiId) CustomEmojiData
    , animationMode : Sticker.AnimationMode
    , timezone : Time.Zone
    , -- Timestamps say how long is left until the moment they point at, so the view needs
      -- to know what the time is now
      time : Time.Posix
    , drawings : SeqDict (Id FileId) (Drawing userId)
    , embedDrawings : SeqDict Int (Drawing userId)
    , drawingUserColor : userId -> UserColor
    , isSelectingAnchor : Bool
    , devicePixelRatio : Float
    , isHovered : Bool
    }


type alias PreviewConfig a userId =
    { domainWhitelist : SeqSet Domain
    , revealedSpoilers : SeqSet Int
    , users : SeqDict userId { a | name : PersonName }
    , attachedFiles : SeqDict (Id FileId) FileData
    , customEmojis : SeqDict (Id CustomEmojiId) CustomEmojiData
    , timezone : Time.Zone
    , time : Time.Posix
    }


bigEmojiFont : Html.Attribute msg
bigEmojiFont =
    Html.Attributes.style "font-family" "\"myemoji\", sans-serif"


normalTextView : String -> RichTextState -> List (Html msg)
normalTextView text state =
    [ Html.span
        [ htmlAttrIf state.italic (Html.Attributes.style "font-style" "italic")
        , htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
        , htmlAttrIf state.bold (Html.Attributes.style "font-weight" "700")
        , htmlAttrIf state.strikethrough (Html.Attributes.style "text-decoration" "line-through")
        , htmlAttrIf state.spoiler (Html.Attributes.style "opacity" "0")
        , bigEmojiFont
        ]
        [ Html.text text ]
    ]


{-| A timestamp is a moment in time rather than a piece of text, so everyone reading the
message sees it in their own timezone. The date is what's worth knowing about something
days away, but for something happening later today the date says nothing the clock doesn't,
so how long is left takes its place.
-}
timestampView : Time.Posix -> Time.Zone -> RichTextState -> TimeInMinutes -> Html msg
timestampView now timezone state time =
    Html.span
        [ htmlAttrIf state.italic (Html.Attributes.style "font-style" "italic")
        , htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
        , htmlAttrIf state.bold (Html.Attributes.style "font-weight" "700")
        , htmlAttrIf state.strikethrough (Html.Attributes.style "text-decoration" "line-through")
        , htmlAttrIf state.spoiler (Html.Attributes.style "opacity" "0")
        , -- Subdued like inline code, so a timestamp doesn't compete with the bright blue
          -- of a user mention
          Html.Attributes.style "background-color" codeBackground
        , Html.Attributes.style "padding" "1px 3px"
        , Html.Attributes.style "border-radius" "3px"
        , Html.Attributes.style "white-space" "nowrap"
        , -- Today's timestamps leave the date out, so hovering brings it back
          Html.Attributes.title (dateAndTimeToString timezone time)
        ]
        [ Html.text (timestampToString now timezone time) ]


timestampToString : Time.Posix -> Time.Zone -> TimeInMinutes -> String
timestampToString now timezone time =
    let
        timeB =
            TimeInMinutes.toTime time
    in
    if isSameDay timezone now timeB then
        MyUi.timestamp timeB timezone ++ " (" ++ timeUntilToString now timeB ++ ")"

    else
        dateAndTimeToString timezone time


dateAndTimeToString : Time.Zone -> TimeInMinutes -> String
dateAndTimeToString timezone time =
    let
        time2 =
            TimeInMinutes.toTime time
    in
    MyUi.datestamp timezone time2 ++ " at " ++ MyUi.timestamp time2 timezone


isSameDay : Time.Zone -> Time.Posix -> Time.Posix -> Bool
isSameDay timezone a b =
    (Time.toYear timezone a == Time.toYear timezone b)
        && (Time.toMonth timezone a == Time.toMonth timezone b)
        && (Time.toDay timezone a == Time.toDay timezone b)


{-| Both are on the same day, so this never has to reach for anything longer than hours.
-}
timeUntilToString : Time.Posix -> Time.Posix -> String
timeUntilToString now time =
    let
        minutesLeft : Int
        minutesLeft =
            (Time.posixToMillis time - Time.posixToMillis now) // 60000

        hours : Int
        hours =
            abs minutesLeft // 60

        minutes : Int
        minutes =
            modBy 60 (abs minutesLeft)

        amount : String
        amount =
            if hours == 0 then
                pluralize minutes "minute"

            else if minutes == 0 then
                pluralize hours "hour"

            else
                pluralize hours "hour" ++ " " ++ pluralize minutes "minute"
    in
    if minutesLeft == 0 then
        "now"

    else if minutesLeft > 0 then
        "in " ++ amount

    else
        amount ++ " ago"


pluralize : Int -> String -> String
pluralize amount unit =
    String.fromInt amount
        ++ "\u{00A0}"
        ++ unit
        ++ (if amount == 1 then
                ""

            else
                "s"
           )


{-| Discord's timestamp syntax, which is where timestamps come from
(<https://discord.com/developers/docs/reference#message-formatting>). The trailing format
hint is dropped when parsing, since at-chat picks the format it shows the timestamp in, so
timestamps are written back out with `f`, the hint closest to that.
-}
timestampToDiscordString : TimeInMinutes -> String
timestampToDiscordString time =
    "<t:" ++ String.fromInt (TimeInMinutes.toSeconds time) ++ ":f>"


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Point2d CssPixels ScreenCoordinate
    , imageSize : Coord CssPixels
    , -- The width the image is displayed at in css pixels. Smaller than the
      -- width in imageSize when the image is scaled down to fit the screen.
      displayWidth : Float
    }


type PressedImageId
    = PressedAttachedFileImage (Id FileId)
    | PressedEmbedImage Int


viewHelper :
    Bool
    -> ShowLargeContent
    -> Maybe ( HtmlId, Int -> msg )
    -> Maybe (PressedImageData -> msg)
    -> (Url -> msg)
    -> Int
    -> RichTextState
    -> Config a userId
    -> Array Embed
    -> Int
    -> Nonempty (RichText userId)
    -> ( ( Bool, Int ), Int, List (Html msg) )
viewHelper dropNextLineBreak showLargeContent maybePressedSpoiler maybeOnPressImage onPressLink spoilerIndex state config embeds embedIndex nonempty =
    List.foldl
        (\item ( ( dropNextLineBreak2, spoilerIndex2 ), embedIndex2, currentList ) ->
            case item of
                UserMention userId ->
                    ( ( False, spoilerIndex2 ), embedIndex2, currentList ++ [ MyUi.userLabelHtml userId config.users ] )

                NormalText char text ->
                    ( ( False, spoilerIndex2 )
                    , embedIndex2
                    , currentList
                        ++ normalTextView
                            (if dropNextLineBreak2 && char == '\n' then
                                text

                             else
                                String.cons char text
                            )
                            state
                    )

                Italic nonempty2 ->
                    let
                        ( ( dropNextLineBreak3, spoilerIndex3 ), embedIndex3, list ) =
                            viewHelper
                                dropNextLineBreak2
                                showLargeContent
                                maybePressedSpoiler
                                maybeOnPressImage
                                onPressLink
                                spoilerIndex2
                                { state | italic = True }
                                config
                                embeds
                                embedIndex2
                                nonempty2
                    in
                    ( ( dropNextLineBreak3, spoilerIndex3 ), embedIndex3, currentList ++ list )

                Underline nonempty2 ->
                    let
                        ( ( dropNextLineBreak3, spoilerIndex3 ), embedIndex3, list ) =
                            viewHelper
                                dropNextLineBreak2
                                showLargeContent
                                maybePressedSpoiler
                                maybeOnPressImage
                                onPressLink
                                spoilerIndex2
                                { state | underline = True }
                                config
                                embeds
                                embedIndex2
                                nonempty2
                    in
                    ( ( dropNextLineBreak3, spoilerIndex3 ), embedIndex3, currentList ++ list )

                Bold nonempty2 ->
                    let
                        ( ( dropNextLineBreak3, spoilerIndex3 ), embedIndex3, list ) =
                            viewHelper
                                dropNextLineBreak2
                                showLargeContent
                                maybePressedSpoiler
                                maybeOnPressImage
                                onPressLink
                                spoilerIndex2
                                { state | bold = True }
                                config
                                embeds
                                embedIndex2
                                nonempty2
                    in
                    ( ( dropNextLineBreak3, spoilerIndex3 ), embedIndex3, currentList ++ list )

                Strikethrough nonempty2 ->
                    let
                        ( ( dropNextLineBreak3, spoilerIndex3 ), embedIndex3, list ) =
                            viewHelper
                                dropNextLineBreak2
                                showLargeContent
                                maybePressedSpoiler
                                maybeOnPressImage
                                onPressLink
                                spoilerIndex2
                                { state | strikethrough = True }
                                config
                                embeds
                                embedIndex2
                                nonempty2
                    in
                    ( ( dropNextLineBreak3, spoilerIndex3 ), embedIndex3, currentList ++ list )

                Spoiler nonempty2 ->
                    let
                        revealed =
                            SeqSet.member spoilerIndex2 config.revealedSpoilers

                        -- Ignore the spoiler index value. It shouldn't be possible to have nested spoilers
                        ( ( dropNextLineBreak3, _ ), embedIndex3, list ) =
                            viewHelper
                                dropNextLineBreak2
                                showLargeContent
                                maybePressedSpoiler
                                maybeOnPressImage
                                onPressLink
                                spoilerIndex2
                                (if revealed then
                                    state

                                 else
                                    { state | spoiler = True }
                                )
                                config
                                embeds
                                embedIndex2
                                nonempty2
                    in
                    ( ( dropNextLineBreak3, spoilerIndex2 + 1 )
                    , embedIndex3
                    , currentList
                        ++ [ Html.span
                                (Html.Attributes.style "border-radius" "2px"
                                    :: (if revealed then
                                            [ Html.Attributes.style "background" "rgb(14,14,16)" ]

                                        else
                                            [ Html.Attributes.style "cursor" "pointer"
                                            , Html.Attributes.style "background" spoilerBackground
                                            ]
                                                ++ (case maybePressedSpoiler of
                                                        Just ( htmlIdPrefix, pressedSpoiler ) ->
                                                            [ Html.Events.onClick (pressedSpoiler spoilerIndex2)
                                                            , Html.Attributes.id
                                                                (Dom.idToString htmlIdPrefix
                                                                    ++ "_"
                                                                    ++ String.fromInt spoilerIndex2
                                                                )
                                                            ]

                                                        Nothing ->
                                                            []
                                                   )
                                       )
                                )
                                list
                           ]
                    )

                BlockQuote _ list ->
                    let
                        sidePadding =
                            8

                        borderLeft =
                            4

                        ( ( _, spoilerIndex3 ), embedIndex3, list2 ) =
                            case List.Nonempty.fromList list of
                                Just nonempty2 ->
                                    viewHelper
                                        True
                                        (case showLargeContent of
                                            ShowLargeContent a ->
                                                ShowLargeContent (a - sidePadding - borderLeft)

                                            NoLargeContent ->
                                                NoLargeContent
                                        )
                                        maybePressedSpoiler
                                        maybeOnPressImage
                                        onPressLink
                                        spoilerIndex2
                                        state
                                        config
                                        embeds
                                        embedIndex2
                                        nonempty2

                                Nothing ->
                                    ( ( True, spoilerIndex2 ), embedIndex2, [ Html.text " " ] )
                    in
                    ( ( True, spoilerIndex3 )
                    , embedIndex3
                    , currentList
                        ++ [ case showLargeContent of
                                ShowLargeContent _ ->
                                    Html.div
                                        [ Html.Attributes.style "border-left" (String.fromInt borderLeft ++ "px solid " ++ accentBarColor)
                                        , Html.Attributes.style "padding" ("2px " ++ String.fromInt sidePadding ++ "px")
                                        ]
                                        list2

                                NoLargeContent ->
                                    Html.span
                                        [ Html.Attributes.style "border-left" (String.fromInt borderLeft ++ "px solid " ++ accentBarColor)
                                        , Html.Attributes.style "padding" ("0px " ++ String.fromInt sidePadding ++ "px")
                                        ]
                                        list2
                           ]
                    )

                Heading level _ nonempty2 ->
                    let
                        ( ( _, spoilerIndex3 ), embedIndex3, list2 ) =
                            viewHelper
                                True
                                showLargeContent
                                maybePressedSpoiler
                                maybeOnPressImage
                                onPressLink
                                spoilerIndex2
                                state
                                config
                                embeds
                                embedIndex2
                                nonempty2

                        headingElement =
                            case showLargeContent of
                                ShowLargeContent _ ->
                                    case level of
                                        H1 ->
                                            Html.h1
                                                [ Html.Attributes.style "font-size" "2em"
                                                , Html.Attributes.style "font-weight" "700"
                                                , Html.Attributes.style "margin" "0"
                                                ]
                                                list2

                                        H2 ->
                                            Html.h2
                                                [ Html.Attributes.style "font-size" "1.5em"
                                                , Html.Attributes.style "font-weight" "700"
                                                , Html.Attributes.style "margin" "0"
                                                ]
                                                list2

                                        H3 ->
                                            Html.h3
                                                [ Html.Attributes.style "font-size" "1.25em"
                                                , Html.Attributes.style "font-weight" "700"
                                                , Html.Attributes.style "margin" "0"
                                                ]
                                                list2

                                        Small ->
                                            Html.div
                                                [ Html.Attributes.style "font-size" "0.8em"
                                                , Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font2)
                                                ]
                                                list2

                                NoLargeContent ->
                                    Html.span
                                        (case level of
                                            Small ->
                                                [ Html.Attributes.style "font-size" "0.8em"
                                                , Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font2)
                                                ]

                                            _ ->
                                                [ Html.Attributes.style "font-weight" "700" ]
                                        )
                                        list2
                    in
                    ( ( True, spoilerIndex3 ), embedIndex3, currentList ++ [ headingElement ] )

                Hyperlink data ->
                    let
                        text : String
                        text =
                            Url.toString data
                    in
                    ( ( False, spoilerIndex2 )
                    , embedIndex2 + 1
                    , currentList
                        ++ [ if state.spoiler then
                                Html.span
                                    [ htmlAttrIf state.italic (Html.Attributes.style "font-style" "italic")
                                    , htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                                    , htmlAttrIf state.bold (Html.Attributes.style "font-weight" "700")
                                    , htmlAttrIf state.strikethrough (Html.Attributes.style "text-decoration" "line-through")
                                    , Html.Attributes.style "opacity" "0"
                                    ]
                                    [ Html.text text ]

                             else
                                case Array.get embedIndex2 embeds of
                                    Just EmbedLoading ->
                                        embedLoadingView onPressLink config.domainWhitelist data

                                    Just (EmbedLoaded embed) ->
                                        case ( embed == Embed.empty, showLargeContent ) of
                                            ( False, ShowLargeContent containerWidth ) ->
                                                embedView
                                                    config.timezone
                                                    onPressLink
                                                    maybeOnPressImage
                                                    containerWidth
                                                    config.domainWhitelist
                                                    config.animationMode
                                                    config.isSelectingAnchor
                                                    embedIndex2
                                                    (case maybePressedSpoiler of
                                                        Just ( htmlIdPrefix, _ ) ->
                                                            Dom.idToString htmlIdPrefix
                                                                ++ "_embedImage_"
                                                                ++ String.fromInt embedIndex2

                                                        Nothing ->
                                                            "embedImage_" ++ String.fromInt embedIndex2
                                                    )
                                                    (case SeqDict.get embedIndex2 config.embedDrawings of
                                                        Just embedDrawing ->
                                                            \scale ->
                                                                Drawing.imageAttachmentOverlays
                                                                    scale
                                                                    config.drawingUserColor
                                                                    embedDrawing

                                                        Nothing ->
                                                            \_ -> []
                                                    )
                                                    data
                                                    embed

                                            _ ->
                                                inlineEmbedView showLargeContent onPressLink config.domainWhitelist data

                                    Nothing ->
                                        inlineEmbedView showLargeContent onPressLink config.domainWhitelist data
                           ]
                    )

                MarkdownLink alias url ->
                    let
                        aliasText : String
                        aliasText =
                            String.Nonempty.toString alias
                    in
                    ( ( False, spoilerIndex2 )
                    , embedIndex2
                    , currentList
                        ++ [ if state.spoiler then
                                Html.span
                                    [ htmlAttrIf state.italic (Html.Attributes.style "font-style" "italic")
                                    , htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                                    , htmlAttrIf state.bold (Html.Attributes.style "font-weight" "700")
                                    , htmlAttrIf state.strikethrough (Html.Attributes.style "text-decoration" "line-through")
                                    , Html.Attributes.style "opacity" "0"
                                    ]
                                    [ Html.text aliasText ]

                             else
                                Html.a
                                    [ Html.Attributes.href (Url.toString url)
                                    , Html.Attributes.target "_blank"
                                    , Html.Attributes.rel "noreferrer"
                                    , Html.Attributes.attribute "data-link-url" (Url.toString url)
                                    , Html.Attributes.style "color" hyperlinkColor
                                    , htmlAttrIf state.italic (Html.Attributes.style "font-style" "italic")
                                    , htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                                    , htmlAttrIf state.bold (Html.Attributes.style "font-weight" "700")
                                    , htmlAttrIf state.strikethrough (Html.Attributes.style "text-decoration" "line-through")
                                    ]
                                    [ Html.text aliasText ]
                           ]
                    )

                InlineCode char rest ->
                    ( ( False, spoilerIndex2 )
                    , embedIndex2
                    , currentList
                        ++ [ Html.span
                                [ htmlAttrIf state.italic (Html.Attributes.style "font-style" "italic")
                                , htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                                , htmlAttrIf state.bold (Html.Attributes.style "text-shadow" "0.7px 0px 0px white")
                                , htmlAttrIf state.strikethrough (Html.Attributes.style "text-decoration" "line-through")
                                , htmlAttrIf state.spoiler (Html.Attributes.style "opacity" "0")
                                , Html.Attributes.style "background-color" codeBackground
                                , Html.Attributes.style "border" (codeBorder ++ " solid 1px")
                                , Html.Attributes.style "padding" "0 4px 0 4px"
                                , Html.Attributes.style "border-radius" "4px"
                                , Html.Attributes.style "font-family" "'DejaVu Sans Mono', monospace"
                                ]
                                [ Html.text (String.cons char rest) ]
                           ]
                    )

                CodeBlock language text ->
                    case showLargeContent of
                        ShowLargeContent containerWidth2 ->
                            ( ( True, spoilerIndex2 )
                            , embedIndex2
                            , currentList
                                ++ [ Html.div
                                        ([ Html.Attributes.style
                                            "background-color"
                                            (if state.spoiler then
                                                spoilerBackground

                                             else
                                                codeBackground
                                            )
                                         , Html.Attributes.style
                                            "border"
                                            (codeBorder ++ " solid " ++ String.fromInt codeBorderWidth ++ "px")
                                         , Html.Attributes.style
                                            "padding"
                                            ("0 " ++ String.fromInt codePaddingX ++ "px")
                                         , Html.Attributes.style "border-radius" "4px"
                                         ]
                                            ++ (if isAsciiArt language then
                                                    [ Html.Attributes.style "font-family" "'ascii', monospace"
                                                    , Html.Attributes.style "line-height" "1"
                                                    , Html.Attributes.style
                                                        "font-size"
                                                        (asciiFontSize containerWidth2 config.devicePixelRatio text)
                                                    , -- Disables subpixel antialiasing on Chrome. Doesn't work on Firefox. I don't know about Safari
                                                      Html.Attributes.style "transform" "translateZ(0)"
                                                    ]

                                                else
                                                    [ Html.Attributes.style "font-family" "'DejaVu Sans Mono', monospace" ]
                                               )
                                        )
                                        [ if state.spoiler then
                                            Html.span [ Html.Attributes.style "opacity" "0" ] [ Html.text text ]

                                          else
                                            Html.text text
                                        ]
                                   ]
                            )

                        NoLargeContent ->
                            ( ( False, spoilerIndex2 ), embedIndex2, currentList ++ [ Html.text "<...>" ] )

                AttachedFile fileId ->
                    case showLargeContent of
                        ShowLargeContent containerWidth2 ->
                            ( ( True, spoilerIndex2 )
                            , embedIndex2
                            , case SeqDict.get fileId config.attachedFiles of
                                Just fileData ->
                                    let
                                        maybeHtmlId : Maybe String
                                        maybeHtmlId =
                                            case maybePressedSpoiler of
                                                Just ( htmlIdPrefix, _ ) ->
                                                    Dom.idToString htmlIdPrefix
                                                        ++ "_file_"
                                                        ++ Id.toString fileId
                                                        |> Just

                                                Nothing ->
                                                    Nothing
                                    in
                                    currentList
                                        ++ [ case fileData.metadata of
                                                Just (FileMetadata_Image { imageSize }) ->
                                                    imageView
                                                        maybePressedSpoiler
                                                        maybeOnPressImage
                                                        containerWidth2
                                                        config
                                                        imageSize
                                                        fileId
                                                        fileData
                                                        state

                                                Just (FileMetadata_Video videoMetadata) ->
                                                    videoView maybeHtmlId (Just videoMetadata) state.spoiler containerWidth2 fileData

                                                Nothing ->
                                                    case FileStatus.contentTypeType fileData.contentType of
                                                        FileStatus.Video ->
                                                            videoView maybeHtmlId Nothing state.spoiler containerWidth2 fileData

                                                        FileStatus.Audio ->
                                                            audioView maybeHtmlId state.spoiler containerWidth2 fileData

                                                        _ ->
                                                            fileDownloadView maybeHtmlId state.spoiler fileData
                                           ]

                                Nothing ->
                                    currentList ++ [ Icons.image 18 ]
                            )

                        NoLargeContent ->
                            ( ( False, spoilerIndex2 ), embedIndex2, currentList ++ [ Icons.image 18 ] )

                EscapedChar char ->
                    ( ( False, spoilerIndex2 ), embedIndex2, currentList ++ [ Html.text (escapedCharToString char) ] )

                Sticker stickerId ->
                    case showLargeContent of
                        ShowLargeContent _ ->
                            ( ( True, spoilerIndex2 )
                            , embedIndex2
                            , currentList ++ [ Sticker.view "160px" stickerId config.stickers config.animationMode ]
                            )

                        NoLargeContent ->
                            ( ( False, spoilerIndex2 ), embedIndex2, currentList ++ [ Icons.image 18 ] )

                CustomEmoji id ->
                    ( ( False, spoilerIndex2 )
                    , embedIndex2
                    , currentList
                        ++ [ case ( showLargeContent, config.isHovered ) of
                                ( ShowLargeContent _, True ) ->
                                    CustomEmoji.viewWithTooltip "1.4em" "0.2em" id config.customEmojis config.animationMode

                                _ ->
                                    CustomEmoji.view "1.4em" "0.2em" id config.customEmojis config.animationMode
                           ]
                    )

                BulletPoint _ items ->
                    let
                        ( ( _, spoilerIndex5 ), embedIndex5, listItems ) =
                            List.foldl
                                (\bulletItem ( ( _, spoilerIndex3 ), embedIndex3, acc ) ->
                                    case List.Nonempty.fromList bulletItem of
                                        Just nonempty2 ->
                                            let
                                                ( ( d4, spoilerIndex4 ), embedIndex4, html ) =
                                                    viewHelper
                                                        True
                                                        (case showLargeContent of
                                                            ShowLargeContent containerWidth ->
                                                                ShowLargeContent (containerWidth - bulletPointLeftPadding)

                                                            NoLargeContent ->
                                                                NoLargeContent
                                                        )
                                                        maybePressedSpoiler
                                                        maybeOnPressImage
                                                        onPressLink
                                                        spoilerIndex3
                                                        state
                                                        config
                                                        embeds
                                                        embedIndex3
                                                        nonempty2
                                            in
                                            ( ( d4, spoilerIndex4 ), embedIndex4, html :: acc )

                                        Nothing ->
                                            ( ( True, spoilerIndex3 ), embedIndex3, acc )
                                )
                                ( ( dropNextLineBreak2, spoilerIndex2 ), embedIndex2, [] )
                                (List.Nonempty.toList items)
                                |> (\( a, b, acc ) -> ( a, b, List.reverse acc ))
                    in
                    ( ( True, spoilerIndex5 )
                    , embedIndex5
                    , currentList
                        ++ (case showLargeContent of
                                ShowLargeContent _ ->
                                    [ Html.ul
                                        [ Html.Attributes.style "margin" "0"
                                        , Html.Attributes.style "padding-left" (String.fromInt bulletPointLeftPadding ++ "px")
                                        ]
                                        (List.map (Html.li []) listItems)
                                    ]

                                NoLargeContent ->
                                    List.concatMap (\a -> Html.text " • " :: a) listItems
                           )
                    )

                Timestamp time ->
                    ( ( False, spoilerIndex2 )
                    , embedIndex2
                    , currentList ++ [ timestampView config.time config.timezone state time ]
                    )
        )
        ( ( dropNextLineBreak, spoilerIndex ), embedIndex, [] )
        (List.Nonempty.toList nonempty)


imageView :
    Maybe ( HtmlId, Int -> msg )
    -> Maybe (PressedImageData -> msg)
    -> Int
    -> Config b userId
    -> Coord CssPixels
    -> Id FileId
    -> FileData
    -> RichTextState
    -> Html msg
imageView maybePressedSpoiler maybeOnPressImage containerWidth2 config imageSize fileId fileData state =
    let
        ( width, height ) =
            actualImageSize FileStatus.imageMaxHeight containerWidth2 imageSize
    in
    if state.spoiler then
        Html.div
            [ Html.Attributes.style "width" (String.fromInt (round width) ++ "px")
            , Html.Attributes.style "height" (String.fromInt (round height) ++ "px")
            , Html.Attributes.style "display" "block"
            , Html.Attributes.style "background-color" spoilerBackground
            ]
            []

    else
        let
            fileUrl =
                FileStatus.fileUrl fileData.contentType fileData.fileHash

            thumbnailUrl =
                FileStatus.thumbnailUrl
                    imageSize
                    fileData.contentType
                    fileData.fileHash

            imageElement : List (Html.Attribute msg) -> Html msg
            imageElement extraAttributes =
                Html.img
                    (Html.Attributes.src thumbnailUrl
                        :: Html.Attributes.style "display" "block"
                        :: MyUi.lazyLoading
                        :: MyUi.imagePlaceholderStyle
                        :: Html.Attributes.width (round width)
                        :: Html.Attributes.height (round height)
                        -- Exposes the full-size image url so that a right-click (contextmenu)
                        -- on the image can offer "Copy image"/"Copy image link" options.
                        :: Html.Attributes.attribute "data-image-url" fileUrl
                        :: extraAttributes
                    )
                    []
        in
        case maybeOnPressImage of
            Just onPressImage ->
                Html.div
                    []
                    [ Html.div
                        [ Html.Attributes.style "position" "relative" ]
                        (case SeqDict.get fileId config.drawings of
                            Just drawing ->
                                Drawing.imageAttachmentOverlays
                                    (width / toFloat (max 1 (Coord.xRaw imageSize)))
                                    config.drawingUserColor
                                    drawing

                            Nothing ->
                                []
                        )
                    , imageElement
                        [ Html.Attributes.style "cursor" "pointer"
                        , Html.Attributes.id
                            (case maybePressedSpoiler of
                                Just ( htmlIdPrefix, _ ) ->
                                    Dom.idToString htmlIdPrefix ++ "_image_" ++ Id.toString fileId

                                Nothing ->
                                    "image_" ++ Id.toString fileId
                            )
                        , Html.Events.on
                            "click"
                            (Json.Decode.map
                                (\position ->
                                    onPressImage
                                        { imageId = PressedAttachedFileImage fileId
                                        , fileUrl = fileUrl
                                        , imageSize = imageSize
                                        , displayWidth = width
                                        , position = position
                                        }
                                )
                                Drawing.decodeWithTargetScreenPosition
                            )
                        , htmlAttrIf config.isSelectingAnchor Drawing.anchorHighlightHtmlClass
                        ]
                    ]

            Nothing ->
                Html.a
                    [ Html.Attributes.href fileUrl
                    , Html.Attributes.target "_blank"
                    , Html.Attributes.rel "noreferrer"
                    , Html.Attributes.style "width" (String.fromInt (round width) ++ "px")
                    , Html.Attributes.style "display" "block"
                    ]
                    [ imageElement [] ]


bulletPointLeftPadding : number
bulletPointLeftPadding =
    24


embedContainerMaxWidth : number
embedContainerMaxWidth =
    432


embedContainerLeftBorderWidth : number
embedContainerLeftBorderWidth =
    4


embedContainerPaddingX : number
embedContainerPaddingX =
    12


embedContainer : List (Html msg) -> Html msg
embedContainer contents =
    Html.div
        [ Html.Attributes.style "display" "flex"
        , Html.Attributes.style "max-width" (String.fromInt embedContainerMaxWidth ++ "px")
        , Html.Attributes.style "margin-top" "4px"
        ]
        [ Html.div
            [ Html.Attributes.style "width" (String.fromInt embedContainerLeftBorderWidth ++ "px")
            , Html.Attributes.style "flex-shrink" "0"
            , Html.Attributes.style "background-color" accentBarColor
            , Html.Attributes.style "border-radius" "4px 0 0 4px"
            ]
            []
        , Html.div
            [ Html.Attributes.style "background-color" (MyUi.colorToStyle MyUi.background2)
            , Html.Attributes.style "padding" ("8px " ++ String.fromInt embedContainerPaddingX ++ "px")
            , Html.Attributes.style "min-width" "0"
            , Html.Attributes.style "flex" "1"
            , -- The corners are rounded per child instead of border-radius and
              -- overflow hidden on the container, so that drawings anchored to
              -- the embed image can extend outside of the container.
              Html.Attributes.style "border-radius" "0 4px 4px 0"
            ]
            contents
        ]


buttonOrA : (Url -> msg) -> SeqSet Domain -> Url -> List (Html.Attribute msg) -> List (Html msg) -> Html msg
buttonOrA onLinkPress domainWhitelist url attributes content =
    if SeqSet.member (urlToDomain url) domainWhitelist then
        Html.a
            (Html.Attributes.href (Url.toString url)
                :: Html.Attributes.target "_blank"
                :: Html.Attributes.rel "noreferrer"
                :: Html.Attributes.attribute "data-link-url" (Url.toString url)
                :: attributes
            )
            content

    else
        Html.span
            (Html.Events.onClick (onLinkPress url)
                :: Html.Attributes.style "cursor" "pointer"
                :: Html.Attributes.style "color" (MyUi.colorToStyle MyUi.textLinkColorOnDarkBackground)
                :: Html.Attributes.attribute "data-link-url" (Url.toString url)
                :: attributes
            )
            content


embedView :
    Time.Zone
    -> (Url -> msg)
    -> Maybe (PressedImageData -> msg)
    -> Int
    -> SeqSet Domain
    -> Sticker.AnimationMode
    -> Bool
    -> Int
    -> String
    -> (Float -> List (Html msg))
    -> Url
    -> EmbedData
    -> Html msg
embedView timezone onPressLink maybeOnPressImage containerWidth domainWhitelist playAnimation isSelectingAnchor embedIndex htmlId drawingOverlays url embed =
    embedContainer
        (List.filterMap
            identity
            [ case embed.title of
                Just title ->
                    buttonOrA
                        onPressLink
                        domainWhitelist
                        url
                        [ Html.Attributes.style "font-size" "14px"
                        , Html.Attributes.style "font-weight" "600"
                        , Html.Attributes.style "color" "rgb(100,160,255)"
                        , Html.Attributes.style "display" "block"
                        , Html.Attributes.style "margin-bottom" "4px"
                        , Html.Attributes.style "text-decoration" "none"
                        , Html.Attributes.style "overflow" "hidden"
                        , Html.Attributes.style "text-overflow" "ellipsis"
                        , Html.Attributes.style "white-space" "nowrap"
                        ]
                        [ Html.text title ]
                        |> Just

                Nothing ->
                    Nothing
            , case embed.description of
                Just content ->
                    Html.div
                        [ Html.Attributes.style "font-size" "13px"
                        , Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font2)
                        , Html.Attributes.style "overflow" "hidden"
                        , Html.Attributes.style "display" "-webkit-box"
                        , Html.Attributes.style "-webkit-line-clamp" "3"
                        , Html.Attributes.style "-webkit-box-orient" "vertical"
                        , Html.Attributes.style "white-space" "pre-wrap"
                        ]
                        [ Html.text (String.left 300 content) ]
                        |> Just

                Nothing ->
                    Nothing
            , case embed.image of
                Just imageData ->
                    let
                        insideWidth : Int
                        insideWidth =
                            min embedContainerMaxWidth containerWidth - embedContainerLeftBorderWidth - embedContainerPaddingX * 2

                        ( width, height ) =
                            actualImageSize embedImageMaxHeight insideWidth imageData.imageSize

                        widthText =
                            String.fromFloat width ++ "px"

                        heightText =
                            String.fromFloat height ++ "px"

                        isAnimatedImage =
                            case imageData.format of
                                Just format ->
                                    case format of
                                        Embed.Gif ->
                                            True

                                        _ ->
                                            False

                                Nothing ->
                                    False

                        image : Html msg
                        image =
                            if isAnimatedImage then
                                Sticker.animatedImageView False widthText heightText Nothing imageData.url playAnimation

                            else
                                Html.img
                                    [ Html.Attributes.src imageData.url
                                    , Html.Attributes.style "width" widthText
                                    , Html.Attributes.style "height" heightText
                                    , Html.Attributes.style "border-radius" "4px"
                                    , MyUi.lazyLoading
                                    , Html.Attributes.style "display" "block"
                                    , MyUi.imagePlaceholderStyle
                                    , Html.Attributes.attribute "data-image-url" imageData.url
                                    ]
                                    []
                    in
                    Html.div
                        ([ Html.Attributes.style "position" "relative"
                         , Html.Attributes.style "width" widthText
                         , htmlAttrIf (not isAnimatedImage) (Html.Attributes.style "margin-top" "8px")
                         ]
                            ++ (case maybeOnPressImage of
                                    Just onPressImage ->
                                        [ Html.Attributes.style "cursor" "pointer"
                                        , Html.Attributes.id htmlId
                                        , Html.Events.on
                                            "click"
                                            (Json.Decode.map
                                                (\position ->
                                                    onPressImage
                                                        { imageId = PressedEmbedImage embedIndex
                                                        , fileUrl = imageData.url
                                                        , imageSize = imageData.imageSize
                                                        , displayWidth = width
                                                        , position = position
                                                        }
                                                )
                                                Drawing.decodeWithTargetScreenPosition
                                            )
                                        , htmlAttrIf isSelectingAnchor Drawing.anchorHighlightHtmlClass
                                        ]

                                    Nothing ->
                                        []
                               )
                        )
                        (drawingOverlays (width / toFloat (max 1 (Coord.xRaw imageData.imageSize))) ++ [ image ])
                        |> Just

                Nothing ->
                    Nothing
            , case embed.createdAt of
                Just createdAt ->
                    Html.div
                        [ Html.Attributes.style "font-size" "11px"
                        , Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font3)
                        , Html.Attributes.style "margin-top" "6px"
                        ]
                        [ Html.text (formatPosix timezone createdAt) ]
                        |> Just

                Nothing ->
                    Nothing
            , smallHyperlink onPressLink domainWhitelist url |> Just
            ]
        )


embedImageMaxHeight : number
embedImageMaxHeight =
    500


actualImageSize : Float -> Int -> Coord units -> ( Float, Float )
actualImageSize maxImageHeight containerWidth2 imageSize =
    let
        w =
            Coord.xRaw imageSize

        h =
            Coord.yRaw imageSize

        aspect =
            toFloat h / toFloat w

        w2 =
            min w containerWidth2

        h2 =
            min (maxImageHeight / 2) (toFloat w2 * aspect)
    in
    ( h2 / aspect, h2 )


embedLoadingView : (Url -> msg) -> SeqSet Domain -> Url -> Html msg
embedLoadingView onPressLink domainWhitelist url =
    embedContainer
        [ Html.div
            [ Html.Attributes.style "width" "60%"
            , Html.Attributes.style "height" "14px"
            , Html.Attributes.style "background-color" (MyUi.colorToStyle MyUi.background3)
            , Html.Attributes.style "border-radius" "4px"
            , Html.Attributes.style "margin-bottom" "8px"
            ]
            []
        , Html.div
            [ Html.Attributes.style "width" "90%"
            , Html.Attributes.style "height" "12px"
            , Html.Attributes.style "background-color" (MyUi.colorToStyle MyUi.background3)
            , Html.Attributes.style "border-radius" "4px"
            , Html.Attributes.style "margin-bottom" "6px"
            ]
            []
        , Html.div
            [ Html.Attributes.style "width" "75%"
            , Html.Attributes.style "height" "12px"
            , Html.Attributes.style "background-color" (MyUi.colorToStyle MyUi.background3)
            , Html.Attributes.style "border-radius" "4px"
            ]
            []
        , smallHyperlink onPressLink domainWhitelist url
        ]


favicon : Url -> String
favicon url =
    "https://icons.duckduckgo.com/ip2/" ++ url.host ++ ".ico"


smallHyperlink : (Url -> msg) -> SeqSet Domain -> Url -> Html msg
smallHyperlink onPressUrl domainWhitelist url =
    let
        path : String
        path =
            url.path
                |> urlAddPrefixed "?" url.query
                |> urlAddPrefixed "#" url.fragment
    in
    buttonOrA
        onPressUrl
        domainWhitelist
        url
        [ Html.Attributes.style "display" "flex"
        , Html.Attributes.style "align-items" "center"
        , Html.Attributes.style "gap" "6px"
        , Html.Attributes.style "margin-top" "4px"
        , Html.Attributes.style "text-decoration" "none"
        ]
        [ Html.img
            [ Html.Attributes.style "width" "16px"
            , Html.Attributes.style "height" "16px"
            , Html.Attributes.style "border-radius" "2px"
            , Html.Attributes.src (favicon url)
            , MyUi.lazyLoading
            ]
            []
        , Html.span
            [ Html.Attributes.style "font-size" "14px"
            , Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font2)
            , Html.Attributes.style "overflow" "hidden"
            , Html.Attributes.style "text-overflow" "ellipsis"
            , Html.Attributes.style "white-space" "nowrap"
            , Html.Attributes.style "min-width" "0"
            ]
            [ if url.protocol == Http then
                Html.span
                    [ Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font3)
                    ]
                    [ Html.text "http://" ]

              else
                Html.text ""
            , Html.text url.host
            , if path == "/" then
                Html.text ""

              else
                Html.span
                    [ Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font3)
                    ]
                    [ Html.text path ]
            ]
        ]


urlAddPrefixed : String -> Maybe String -> String -> String
urlAddPrefixed prefix maybeSegment starter =
    case maybeSegment of
        Nothing ->
            starter

        Just segment ->
            starter ++ prefix ++ segment


formatPosix : Time.Zone -> Time.Posix -> String
formatPosix timezone time =
    MyUi.datestamp timezone time


inlineEmbedView : ShowLargeContent -> (Url -> msg) -> SeqSet Domain -> Url -> Html msg
inlineEmbedView showLargeContent onPressUrl domainWhitelist url =
    let
        path : String
        path =
            url.path
                |> urlAddPrefixed "?" url.query
                |> urlAddPrefixed "#" url.fragment

        width : Int
        width =
            case showLargeContent of
                ShowLargeContent containerWidth ->
                    containerWidth

                NoLargeContent ->
                    600
    in
    buttonOrA
        onPressUrl
        domainWhitelist
        url
        [ Html.Attributes.style "display" "inline-block"
        , Html.Attributes.style "max-width" (String.fromInt (min 600 (width - 4)) ++ "px")
        , Html.Attributes.style "border-radius" "4px"
        , Html.Attributes.style "overflow" "hidden"
        , Html.Attributes.style "text-overflow" "ellipsis"
        , Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font2)
        , Html.Attributes.style "background-color" (MyUi.colorToStyle MyUi.background2)
        , Html.Attributes.style "white-space" "nowrap"
        , Html.Attributes.style "transform" "translateY(0.3em)"
        , Html.Attributes.style "border-left" ("solid 5px " ++ accentBarColor)
        , Html.Attributes.style "padding-right" "4px"
        ]
        [ Html.img
            [ Html.Attributes.style "width" "1em"
            , Html.Attributes.style "height" "1em"
            , Html.Attributes.style "border-radius" "2px"
            , Html.Attributes.style "transform" "translateY(0.125em)"
            , Html.Attributes.style "padding" "0 4px 0 4px"
            , Html.Attributes.src (favicon url)
            , MyUi.lazyLoading
            ]
            []
        , if url.protocol == Http then
            Html.span
                [ Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font3)
                ]
                [ Html.text "http://" ]

          else
            Html.text ""
        , Html.text url.host
        , if path == "/" then
            Html.text ""

          else
            Html.span
                [ Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font3)
                ]
                [ Html.text path ]
        ]


videoView : Maybe String -> Maybe VideoMetadata -> Bool -> Int -> FileData -> Html msg
videoView maybeHtmlId maybeMetadata isSpoilered containerWidth fileData =
    let
        idAttribute : Html.Attribute msg
        idAttribute =
            case maybeHtmlId of
                Just htmlId ->
                    Html.Attributes.id htmlId

                Nothing ->
                    Html.Attributes.class ""

        sizeAttrs : List (Html.Attribute msg)
        sizeAttrs =
            case maybeMetadata of
                Just metadata ->
                    let
                        ( width, height ) =
                            actualImageSize FileStatus.imageMaxHeight containerWidth metadata.videoSize
                    in
                    [ Html.Attributes.style "width" (String.fromFloat width ++ "px")
                    , Html.Attributes.style "height" (String.fromFloat height ++ "px")
                    ]

                Nothing ->
                    [ Html.Attributes.style "height" "300px" ]
    in
    if isSpoilered then
        Html.div
            (sizeAttrs
                ++ [ idAttribute
                   , Html.Attributes.style "display" "block"
                   , Html.Attributes.style "border-radius" "4px"
                   , Html.Attributes.style "background-color" spoilerBackground
                   ]
            )
            []

    else
        Html.video
            (sizeAttrs
                ++ [ idAttribute
                   , Html.Attributes.src (FileStatus.fileUrl fileData.contentType fileData.fileHash)
                   , Html.Attributes.controls True
                   , Html.Attributes.style "display" "block"
                   , Html.Attributes.style "border-radius" "4px"
                   ]
            )
            []


audioView : Maybe String -> Bool -> Int -> FileData -> Html msg
audioView maybeHtmlId isSpoilered containerWidth fileData =
    let
        idAttribute : Html.Attribute msg
        idAttribute =
            case maybeHtmlId of
                Just htmlId ->
                    Html.Attributes.id htmlId

                Nothing ->
                    Html.Attributes.class ""

        width : Int
        width =
            min containerWidth 600
    in
    Html.div
        (Html.Attributes.style "width" (String.fromInt width ++ "px")
            :: (if isSpoilered then
                    [ Html.Attributes.style "background-color" spoilerBackground
                    ]

                else
                    []
               )
        )
        [ Html.audio
            ([ Html.Attributes.src (FileStatus.fileUrl fileData.contentType fileData.fileHash)
             , Html.Attributes.controls True
             , Html.Attributes.style "display" "block"
             , Html.Attributes.style "width" (String.fromInt width ++ "px")
             , idAttribute
             ]
                ++ (if isSpoilered then
                        [ Html.Attributes.style "pointer-events" "none"
                        , Html.Attributes.style "opacity" "0"
                        ]

                    else
                        []
                   )
            )
            []
        ]


fileDownloadView : Maybe String -> Bool -> FileData -> Html msg
fileDownloadView maybeHtmlId isSpoilered fileData =
    let
        fileUrl =
            FileStatus.fileUrl fileData.contentType fileData.fileHash
    in
    Html.a
        [ case maybeHtmlId of
            Just htmlId ->
                Html.Attributes.id htmlId

            Nothing ->
                Html.Attributes.class ""
        , Html.Attributes.style "max-width" "284px"
        , Html.Attributes.style
            "background-color"
            (if isSpoilered then
                spoilerBackground

             else
                MyUi.colorToStyle MyUi.background1
            )
        , Html.Attributes.style "border-radius" "4px"
        , Html.Attributes.style "border" ("solid 1px " ++ MyUi.colorToStyle MyUi.border1)
        , Html.Attributes.style "display" "block"
        , if isSpoilered then
            Html.Attributes.style "color" "transparent"

          else
            Html.Attributes.href fileUrl
        , Html.Attributes.download (FileName.toString fileData.fileName)
        , Html.Attributes.target "_blank"
        , Html.Attributes.rel "noreferrer"
        , Html.Attributes.style "font-size" "14px"
        , Html.Attributes.style "padding" "4px 8px 4px 8px"
        ]
        [ Html.text (FileName.toString fileData.fileName)
        , Html.text ("\n" ++ FileStatus.sizeToString fileData.fileSize ++ " ")
        , Html.div
            [ Html.Attributes.style "display" "inline-block"
            , Html.Attributes.style "transform" "translateY(4px)"
            , htmlAttrIf isSpoilered (Html.Attributes.style "opacity" "0")
            ]
            [ Icons.download ]
        ]


textInputView :
    Time.Zone
    -> SeqDict userId { a | name : PersonName }
    -> SeqDict (Id FileId) b
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> SeqDict (Id StickerId) StickerData
    -> Maybe Range
    -> Nonempty (RichText userId)
    -> List (Html msg)
textInputView timezone users attachedFiles customEmojis2 stickers2 selection nonempty =
    textInputViewHelper
        timezone
        { underline = False, italic = False, bold = False, strikethrough = False, spoiler = False }
        users
        attachedFiles
        customEmojis2
        stickers2
        0
        selection
        (List.Nonempty.toList nonempty)
        False
        Array.empty
        |> Tuple.second
        |> Array.toList


htmlAttrIf : Bool -> Html.Attribute msg -> Html.Attribute msg
htmlAttrIf condition attribute =
    if condition then
        attribute

    else
        Html.Attributes.style "" ""


type alias RichTextState =
    { italic : Bool, underline : Bool, bold : Bool, strikethrough : Bool, spoiler : Bool }


textInputViewHelper :
    Time.Zone
    -> RichTextState
    -> SeqDict userId { a | name : PersonName }
    -> SeqDict (Id FileId) b
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> SeqDict (Id StickerId) StickerData
    -> Int
    -> Maybe Range
    -> List (RichText userId)
    -> Bool
    -> Array (Html msg)
    -> ( Int, Array (Html msg) )
textInputViewHelper timezone state allUsers attachedFiles customEmojis2 stickers2 index selection list inBlockQuote output =
    List.foldl
        (\item ( index2, output2 ) ->
            case item of
                UserMention userId ->
                    case SeqDict.get userId allUsers of
                        Just user ->
                            let
                                text =
                                    "@" ++ PersonName.toString user.name
                            in
                            ( index2 + String.length text
                            , Array.push
                                (Html.span
                                    [ Html.Attributes.style "color" (MyUi.colorToStyle MyUi.userLabelFontColor)
                                    , Html.Attributes.style "background-color" "rgba(57,77,255,0.5)"
                                    , Html.Attributes.style "border-radius" "2px"
                                    ]
                                    (textWithSelection selection index2 text)
                                )
                                output2
                            )

                        Nothing ->
                            ( index2 + 1, output2 )

                NormalText char text ->
                    let
                        text2 =
                            String.cons char text

                        helper startIndex text4 =
                            Html.span
                                [ htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                                , htmlAttrIf state.bold (Html.Attributes.style "text-shadow" "0.7px 0px 0px white")
                                , htmlAttrIf state.strikethrough (Html.Attributes.style "text-decoration" "line-through")
                                , htmlAttrIf state.spoiler (Html.Attributes.style "background-color" spoilerBackground)
                                ]
                                (textWithSelection selection startIndex text4)
                    in
                    if inBlockQuote then
                        -- Each line after the first starts with "\n> " in the text the user typed but
                        -- parseBlockQuoteContent timezone drops the "> ", so the index has to skip 3 characters
                        -- per line here even though this text only contains the "\n".
                        case String.split "\n" text2 of
                            first :: rest ->
                                List.foldl
                                    (\line ( index3, output3 ) ->
                                        ( index3 + 3 + String.length line
                                        , Array.push
                                            (helper (index3 + 3) line)
                                            (Array.push (formatText selection index3 "\n> ") output3)
                                        )
                                    )
                                    ( index2 + String.length first
                                    , Array.push (helper index2 first) output2
                                    )
                                    rest

                            [] ->
                                ( index2, output2 )

                    else
                        ( index2 + String.length text2
                        , Array.push (helper index2 text2) output2
                        )

                Italic nonempty2 ->
                    let
                        ( index3, output3 ) =
                            textInputViewHelper
                                timezone
                                { state | italic = True }
                                allUsers
                                attachedFiles
                                customEmojis2
                                stickers2
                                (index2 + 1)
                                selection
                                (List.Nonempty.toList nonempty2)
                                inBlockQuote
                                (Array.push (formatText selection index2 "_") output2)
                    in
                    ( index3 + 1, Array.push (formatText selection index3 "_") output3 )

                Underline nonempty2 ->
                    let
                        ( index3, output3 ) =
                            textInputViewHelper
                                timezone
                                { state | underline = True }
                                allUsers
                                attachedFiles
                                customEmojis2
                                stickers2
                                (index2 + 2)
                                selection
                                (List.Nonempty.toList nonempty2)
                                inBlockQuote
                                (Array.push (formatText selection index2 "__") output2)
                    in
                    ( index3 + 2, Array.push (formatText selection index3 "__") output3 )

                Bold nonempty2 ->
                    let
                        ( index3, output3 ) =
                            textInputViewHelper
                                timezone
                                { state | bold = True }
                                allUsers
                                attachedFiles
                                customEmojis2
                                stickers2
                                (index2 + 1)
                                selection
                                (List.Nonempty.toList nonempty2)
                                inBlockQuote
                                (Array.push (formatText selection index2 "*") output2)
                    in
                    ( index3 + 1, Array.push (formatText selection index3 "*") output3 )

                Strikethrough nonempty2 ->
                    let
                        ( index3, output3 ) =
                            textInputViewHelper
                                timezone
                                { state | strikethrough = True }
                                allUsers
                                attachedFiles
                                customEmojis2
                                stickers2
                                (index2 + 2)
                                selection
                                (List.Nonempty.toList nonempty2)
                                inBlockQuote
                                (Array.push (formatText selection index2 "~~") output2)
                    in
                    ( index3 + 2, Array.push (formatText selection index3 "~~") output3 )

                Spoiler nonempty2 ->
                    let
                        ( index3, output3 ) =
                            textInputViewHelper
                                timezone
                                { state | spoiler = True }
                                allUsers
                                attachedFiles
                                customEmojis2
                                stickers2
                                (index2 + 2)
                                selection
                                (List.Nonempty.toList nonempty2)
                                inBlockQuote
                                (Array.push (formatText selection index2 "||") output2)
                    in
                    ( index3 + 2, Array.push (formatText selection index3 "||") output3 )

                BlockQuote hasLeadingLineBreak nonempty2 ->
                    let
                        marker : String
                        marker =
                            case hasLeadingLineBreak of
                                HasLeadingLineBreak ->
                                    "\n> "

                                NoLeadingLineBreak ->
                                    "> "
                    in
                    textInputViewHelper
                        timezone
                        state
                        allUsers
                        attachedFiles
                        customEmojis2
                        stickers2
                        (index2 + String.length marker)
                        selection
                        nonempty2
                        True
                        (Array.push (formatText selection index2 marker) output2)

                Heading level hasLeadingLineBreak nonempty2 ->
                    let
                        marker : String
                        marker =
                            (case hasLeadingLineBreak of
                                HasLeadingLineBreak ->
                                    "\n"

                                NoLeadingLineBreak ->
                                    ""
                            )
                                ++ headingLevelToMarker level
                    in
                    textInputViewHelper
                        timezone
                        state
                        allUsers
                        attachedFiles
                        customEmojis2
                        stickers2
                        (index2 + String.length marker)
                        selection
                        (List.Nonempty.toList nonempty2)
                        inBlockQuote
                        (Array.push (formatText selection index2 marker) output2)

                Hyperlink data ->
                    let
                        text =
                            Url.toString data
                    in
                    ( index2 + String.length text
                    , Array.push
                        (Html.span
                            [ htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                            , htmlAttrIf state.bold (Html.Attributes.style "text-shadow" "0.7px 0px 0px white")
                            , htmlAttrIf state.strikethrough (Html.Attributes.style "text-decoration" "line-through")
                            , htmlAttrIf state.spoiler (Html.Attributes.style "background-color" spoilerBackground)
                            , Html.Attributes.style "color" (MyUi.colorToStyle MyUi.textLinkColor)
                            ]
                            (textWithSelection selection index2 text)
                        )
                        output2
                    )

                MarkdownLink alias url ->
                    let
                        text =
                            "[" ++ String.Nonempty.toString alias ++ "](" ++ Url.toString url ++ ")"
                    in
                    ( index2 + String.length text
                    , Array.push
                        (Html.span
                            [ htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                            , htmlAttrIf state.bold (Html.Attributes.style "text-shadow" "0.7px 0px 0px white")
                            , htmlAttrIf state.strikethrough (Html.Attributes.style "text-decoration" "line-through")
                            , htmlAttrIf state.spoiler (Html.Attributes.style "background-color" spoilerBackground)
                            , Html.Attributes.style "color" (MyUi.colorToStyle MyUi.textLinkColor)
                            ]
                            (textWithSelection selection index2 text)
                        )
                        output2
                    )

                InlineCode char rest ->
                    ( index2 + String.length rest + 3
                    , Array.append
                        output2
                        (Array.fromList
                            [ formatText selection index2 "`"
                            , Html.span
                                [ htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                                , htmlAttrIf state.bold (Html.Attributes.style "text-shadow" "0.7px 0px 0px white")
                                , htmlAttrIf state.strikethrough (Html.Attributes.style "text-decoration" "line-through")
                                , if state.spoiler then
                                    Html.Attributes.style "background-color" spoilerBackground

                                  else
                                    Html.Attributes.style "background-color" codeBackground
                                ]
                                (textWithSelection selection (index2 + 1) (String.cons char rest))
                            , formatText selection (index2 + 2 + String.length rest) "`"
                            ]
                        )
                    )

                CodeBlock language string ->
                    let
                        language2 : String
                        language2 =
                            case language of
                                Language a ->
                                    String.Nonempty.toString a ++ "\n"

                                NoLanguage ->
                                    ""
                    in
                    ( index2 + String.length string + String.length language2 + 6
                    , Array.append output2
                        (Array.fromList
                            [ formatText selection index2 ("```" ++ language2)
                            , Html.span [] (textWithSelection selection (index2 + 3 + String.length language2) string)
                            , formatText selection (index2 + 3 + String.length language2 + String.length string) "```"
                            ]
                        )
                    )

                AttachedFile fileId ->
                    let
                        text : String
                        text =
                            attachedFilePrefix ++ Id.toString fileId ++ attachedFileSuffix
                    in
                    ( index2 + String.length text
                    , Array.push
                        (if SeqDict.member fileId attachedFiles then
                            formatText selection index2 text

                         else
                            Html.span [] (textWithSelection selection index2 text)
                        )
                        output2
                    )

                EscapedChar char ->
                    ( index2 + 2
                    , Array.append output2
                        (Array.fromList
                            [ formatText selection index2 "\\"
                            , Html.span [] (textWithSelection selection (index2 + 1) (escapedCharToString char))
                            ]
                        )
                    )

                Sticker stickerId ->
                    let
                        isSelected =
                            case selection of
                                Just selection2 ->
                                    index2 >= selection2.start && index2 < selection2.end

                                Nothing ->
                                    False
                    in
                    ( index2 + String.length (Sticker.idToString stickerId)
                    , Array.append
                        output2
                        (Array.fromList
                            [ Html.text "\n"
                            , Html.span
                                [ Html.Attributes.style "position" "relative" ]
                                [ Html.div
                                    [ Html.Attributes.style "position" "absolute"
                                    , if isSelected then
                                        Html.Attributes.style "background-color" (MyUi.colorToStyle MyUi.selectedTextBackground)

                                      else
                                        Html.Attributes.style "opacity" "transparent"
                                    , Html.Attributes.style "top" "0"
                                    , Html.Attributes.style "left" "0"
                                    ]
                                    [ Sticker.view "2lh" stickerId stickers2 Sticker.LoopForever ]
                                , Html.div
                                    [ Html.Attributes.style "position" "absolute"
                                    , Html.Attributes.style "width" "2lh"
                                    , Html.Attributes.style "height" "2lh"
                                    , if isSelected then
                                        Html.Attributes.style
                                            "background-color"
                                            (MyUi.colorToStyle (MyUi.colorWithAlpha 0.5 MyUi.selectedTextBackground))

                                      else
                                        Html.Attributes.style "opacity" "transparent"
                                    , Html.Attributes.style "top" "0"
                                    , Html.Attributes.style "left" "0"
                                    ]
                                    []
                                ]
                            , Html.text "\n\n"
                            ]
                        )
                    )

                CustomEmoji customEmojiId ->
                    let
                        text =
                            CustomEmoji.idToString customEmojiId

                        isSelected =
                            case selection of
                                Just selection2 ->
                                    index2 >= selection2.start && index2 < selection2.end

                                Nothing ->
                                    False
                    in
                    ( index2 + String.length text
                    , Array.append
                        output2
                        (Array.fromList
                            [ Html.span
                                [ Html.Attributes.style "position" "relative" ]
                                [ Html.div
                                    [ Html.Attributes.style "position" "absolute"
                                    , if isSelected then
                                        Html.Attributes.style "background-color" (MyUi.colorToStyle MyUi.selectedTextBackground)

                                      else
                                        Html.Attributes.style "background-color" (MyUi.colorToStyle MyUi.background2)
                                    , Html.Attributes.style "top" "-0.1em"
                                    , Html.Attributes.style "left" "0.1em"
                                    , Html.Attributes.style "width" "1.4em"
                                    , Html.Attributes.style "height" "1.6em"
                                    ]
                                    []
                                , Html.div
                                    [ Html.Attributes.style "position" "absolute"
                                    , Html.Attributes.style "top" "0"
                                    , Html.Attributes.style "left" "0.1em"
                                    ]
                                    [ CustomEmoji.view "1.4em" "0" customEmojiId customEmojis2 Sticker.LoopForever ]
                                ]
                            , Html.span [] [ Html.text text ]
                            ]
                        )
                    )

                BulletPoint hasLeadingLineBreak items ->
                    let
                        leading : String
                        leading =
                            case hasLeadingLineBreak of
                                HasLeadingLineBreak ->
                                    "\n"

                                NoLeadingLineBreak ->
                                    ""
                    in
                    List.foldl
                        (\( itemIndex, bulletItem ) ( index3, output3 ) ->
                            let
                                marker : String
                                marker =
                                    if itemIndex == 0 then
                                        leading ++ "* "

                                    else
                                        "\n* "
                            in
                            textInputViewHelper
                                timezone
                                state
                                allUsers
                                attachedFiles
                                customEmojis2
                                stickers2
                                (index3 + String.length marker)
                                selection
                                bulletItem
                                inBlockQuote
                                (Array.push (formatText selection index3 marker) output3)
                        )
                        ( index2, output2 )
                        (List.indexedMap Tuple.pair (List.Nonempty.toList items))

                Timestamp time ->
                    let
                        text : String
                        text =
                            dateAndTimeToString timezone time
                    in
                    ( index2 + String.length text
                    , Array.push (formatText selection index2 text) output2
                    )
        )
        ( index, output )
        list


formatText : Maybe Range -> Int -> String -> Html msg
formatText selection startIndex text =
    Html.span
        [ Html.Attributes.style "color" "rgb(140,140,140)" ]
        (textWithSelection selection startIndex text)


{-| The message input's textarea is drawn on top of the rich text so that the caret stays visible.
That means the textarea's own selection highlight would cover the rich text, so it's transparent
(see the rich-text-input rules in MyUi.css) and the highlight is drawn here instead.

`startIndex` is where `text` starts within the text the user typed.

-}
textWithSelection : Maybe Range -> Int -> String -> List (Html msg)
textWithSelection selection startIndex text =
    case selection of
        Just { start, end } ->
            let
                selectionStart : Int
                selectionStart =
                    clamp 0 (String.length text) (start - startIndex)

                selectionEnd : Int
                selectionEnd =
                    clamp 0 (String.length text) (end - startIndex)
            in
            if selectionEnd <= selectionStart then
                [ Html.text text ]

            else
                [ Html.text (String.left selectionStart text)
                , Html.span
                    [ Html.Attributes.style "background-color" (MyUi.colorToStyle MyUi.selectedTextBackground) ]
                    [ Html.text (String.slice selectionStart selectionEnd text) ]
                , Html.text (String.dropLeft selectionEnd text)
                ]

        Nothing ->
            [ Html.text text ]



--
--fromSlack : List Slack.Block -> Nonempty (RichText (Slack.Id Slack.UserId))
--fromSlack blocks =
--    List.concatMap
--        (\block ->
--            case block of
--                Slack.RichTextBlock elements ->
--                    List.concatMap
--                        (\element ->
--                            case element of
--                                Slack.RichTextSection elements2 ->
--                                    List.filterMap
--                                        (\element2 ->
--                                            case element2 of
--                                                Slack.RichText_Text data ->
--                                                    case String.Nonempty.fromString data.text of
--                                                        Just text ->
--                                                            (if data.code then
--                                                                InlineCode (String.Nonempty.head text) (String.Nonempty.tail text)
--
--                                                             else
--                                                                NormalText (String.Nonempty.head text) (String.Nonempty.tail text)
--                                                            )
--                                                                |> (\a ->
--                                                                        if data.italic then
--                                                                            Italic (Nonempty a [])
--
--                                                                        else
--                                                                            a
--                                                                   )
--                                                                |> (\a ->
--                                                                        if data.bold then
--                                                                            Bold (Nonempty a [])
--
--                                                                        else
--                                                                            a
--                                                                   )
--                                                                |> (\a ->
--                                                                        if data.strikethrough then
--                                                                            Strikethrough (Nonempty a [])
--
--                                                                        else
--                                                                            a
--                                                                   )
--                                                                |> Just
--
--                                                        Nothing ->
--                                                            Nothing
--
--                                                Slack.RichText_Emoji data ->
--                                                    NormalText
--                                                        (String.Nonempty.head data.unicode)
--                                                        (String.Nonempty.tail data.unicode)
--                                                        |> Just
--
--                                                Slack.RichText_UserMention id ->
--                                                    UserMention id |> Just
--                                        )
--                                        elements2
--
--                                Slack.RichTextPreformattedSection elements2 ->
--                                    [ List.filterMap
--                                        (\element2 ->
--                                            case element2 of
--                                                Slack.RichText_Text data ->
--                                                    Just data.text
--
--                                                Slack.RichText_Emoji _ ->
--                                                    Nothing
--
--                                                Slack.RichText_UserMention _ ->
--                                                    Nothing
--                                        )
--                                        elements2
--                                        |> String.concat
--                                        |> CodeBlock NoLanguage
--                                    ]
--                        )
--                        elements
--        )
--        blocks
--        |> List.Nonempty.fromList
--        |> Maybe.withDefault (Nonempty (Italic (Nonempty (NormalText 'M' "essage is empty") [])) [])


fromDiscord :
    String
    -> SeqDict (Id FileId) { fileData : FileData, isSpoilered : Bool }
    -> Discord.OptionalData (List Discord.Embed)
    -> OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
    -> List (Id StickerId)
    -> Discord.OptionalData (List Discord.MessageSnapshot)
    -> Nonempty (RichText (Discord.Id Discord.UserId))
fromDiscord text attachments2 embeds customEmojis2 stickers2 messageSnapshots =
    let
        messageSnapshots3 : List (RichText (Discord.Id Discord.UserId))
        messageSnapshots3 =
            case messageSnapshots of
                Discord.Included messageSnapshots2 ->
                    List.map
                        (\snapshot ->
                            fromDiscordHelper
                                snapshot.content
                                -- TODO: Handle attachments for message snapshots
                                SeqDict.empty
                                (Discord.Included snapshot.embeds)
                                -- TODO: Handle stickers for message snapshots
                                customEmojis2
                                []
                                |> BlockQuote NoLeadingLineBreak
                        )
                        messageSnapshots2

                Discord.Missing ->
                    []
    in
    (fromDiscordHelper text attachments2 embeds customEmojis2 stickers2 ++ messageSnapshots3)
        |> List.Nonempty.fromList
        |> Maybe.withDefault emptyPlaceholder


fromDiscordHelper :
    String
    -> SeqDict (Id FileId) { fileData : FileData, isSpoilered : Bool }
    -> Discord.OptionalData (List Discord.Embed)
    -> OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
    -> List (Id StickerId)
    -> List (RichText (Discord.Id Discord.UserId))
fromDiscordHelper text attachments2 embeds customEmojis2 stickers2 =
    let
        ( urlEmbeds, richTextEmbeds ) =
            List.foldl
                (\embed ( urlEmbeds2, richTextEmbeds2 ) ->
                    case embed.url of
                        Discord.Included url ->
                            case Url.fromString url of
                                Just url2 ->
                                    ( SeqSet.insert url2 urlEmbeds2, richTextEmbeds2 )

                                Nothing ->
                                    ( urlEmbeds2, richTextEmbeds2 )

                        Discord.Missing ->
                            case embed.type_ of
                                Discord.Included EmbedType_Rich ->
                                    ( urlEmbeds2
                                    , richTextEmbeds2
                                        ++ [ (case embed.title of
                                                Discord.Included title ->
                                                    title ++ "\n"

                                                Discord.Missing ->
                                                    ""
                                             )
                                                ++ (case embed.description of
                                                        Discord.Included description ->
                                                            description ++ "\n"

                                                        Discord.Missing ->
                                                            ""
                                                   )
                                           ]
                                    )

                                _ ->
                                    ( urlEmbeds2, richTextEmbeds2 )
                )
                ( SeqSet.empty, [] )
                (case embeds of
                    Discord.Included embeds2 ->
                        embeds2

                    Discord.Missing ->
                        []
                )

        applyExtraEmbeds : Nonempty (RichText userId) -> Nonempty (RichText userId)
        applyExtraEmbeds richText =
            let
                urls : List Url
                urls =
                    hyperlinks richText
            in
            --This is to detect if we actually have embeds that are not attached to any url or if we just have embeds with canonicalized urls that don't match up with the urls in the message
            if SeqSet.size urlEmbeds > List.length urls then
                case
                    List.foldl SeqSet.remove urlEmbeds urls
                        |> SeqSet.toList
                        |> List.concatMap (\url -> [ NormalText ' ' "", Hyperlink url ])
                        |> List.Nonempty.fromList
                of
                    Just nonempty ->
                        List.Nonempty.append richText nonempty

                    Nothing ->
                        richText

            else
                richText

        applyStickers : List (RichText userId) -> List (RichText userId)
        applyStickers richText =
            richText ++ List.map Sticker stickers2

        spoileredAttachments : List (RichText userId)
        spoileredAttachments =
            List.map
                (\( fileId, attachment ) ->
                    if attachment.isSpoilered then
                        Spoiler (Nonempty (AttachedFile fileId) [])

                    else
                        AttachedFile fileId
                )
                (SeqDict.toList attachments2)

        text2 =
            if String.isEmpty text then
                String.join "\n" richTextEmbeds |> String.trim

            else
                text ++ "\n" ++ String.join "\n" richTextEmbeds |> String.trimRight
    in
    case String.Nonempty.fromString text2 of
        Just nonempty ->
            NonemptyExtra.appendList
                (let
                    source =
                        String.Nonempty.toString nonempty

                    ( startIndex, startRevNodes ) =
                        case extractBlockQuote source 0 of
                            Just ( content, endIndex ) ->
                                ( endIndex, [ BlockQuote NoLeadingLineBreak (parseDiscordBlockQuoteContent customEmojis2 content) ] )

                            Nothing ->
                                case extractHeading source 0 of
                                    Just ( level, content, endIndex ) ->
                                        ( endIndex, [ Heading level NoLeadingLineBreak (parseDiscordHeadingContent customEmojis2 content) ] )

                                    Nothing ->
                                        case extractBulletPoint starOrDashBulletMarker (parseDiscordBlockQuoteContent customEmojis2) source 0 of
                                            Just bullet ->
                                                ( bullet.endIndex
                                                , bulletRevNodes (BulletPoint NoLeadingLineBreak bullet.items) bullet.trailing []
                                                )

                                            Nothing ->
                                                ( 0, [] )

                    result =
                        discordParseLoop customEmojis2 source startIndex [] "" startRevNodes
                 in
                 case List.Nonempty.fromList result.nodes of
                    Just nonempty2 ->
                        normalize nonempty2

                    Nothing ->
                        Nonempty (normalTextFromNonempty nonempty) []
                )
                spoileredAttachments
                |> applyExtraEmbeds
                |> List.Nonempty.toList
                |> applyStickers

        Nothing ->
            case List.Nonempty.fromList spoileredAttachments of
                Just spoileredAttachments2 ->
                    applyExtraEmbeds spoileredAttachments2 |> List.Nonempty.toList |> applyStickers

                Nothing ->
                    SeqSet.toList urlEmbeds
                        |> List.map Hyperlink
                        |> List.intersperse (NormalText ' ' "")
                        |> applyStickers


emptyPlaceholder : Nonempty (RichText userId)
emptyPlaceholder =
    Nonempty (NormalText '<' "empty>") []


type DiscordModifiers
    = DiscordIsBold
    | DiscordIsItalic
    | DiscordIsItalic2
    | DiscordIsUnderlined
    | DiscordIsStrikethrough
    | DiscordIsSpoilered


discordModifierToSymbol : DiscordModifiers -> NonemptyString
discordModifierToSymbol modifier =
    case modifier of
        DiscordIsBold ->
            NonemptyString '*' "*"

        DiscordIsItalic ->
            NonemptyString '*' ""

        DiscordIsItalic2 ->
            NonemptyString '_' ""

        DiscordIsUnderlined ->
            NonemptyString '_' "_"

        DiscordIsStrikethrough ->
            NonemptyString '~' "~"

        DiscordIsSpoilered ->
            NonemptyString '|' "|"


{-| <https://discord.com/developers/docs/reference#message-formatting>
-}
discordParseLoop :
    OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
    -> String
    -> Int
    -> List DiscordModifiers
    -> String
    -> List (RichText (Discord.Id Discord.UserId))
    -> { nodes : List (RichText (Discord.Id Discord.UserId)), nextIndex : Int }
discordParseLoop customEmojis2 source index modifiers accText revNodes =
    if index >= String.length source then
        finalizeResult discordModifierToSymbol accText revNodes modifiers index

    else
        case String.slice index (index + 1) source of
            "\n" ->
                if List.isEmpty modifiers then
                    case extractBlockQuote source (index + 1) of
                        Just ( content, endIndex ) ->
                            discordParseLoop
                                customEmojis2
                                source
                                endIndex
                                modifiers
                                ""
                                (BlockQuote HasLeadingLineBreak (parseDiscordBlockQuoteContent customEmojis2 content)
                                    :: flushText accText revNodes
                                )

                        Nothing ->
                            case extractHeading source (index + 1) of
                                Just ( level, content, endIndex ) ->
                                    discordParseLoop
                                        customEmojis2
                                        source
                                        endIndex
                                        modifiers
                                        ""
                                        (Heading level HasLeadingLineBreak (parseDiscordHeadingContent customEmojis2 content)
                                            :: flushText accText revNodes
                                        )

                                Nothing ->
                                    case extractBulletPoint starOrDashBulletMarker (parseDiscordBlockQuoteContent customEmojis2) source (index + 1) of
                                        Just bullet ->
                                            discordParseLoop
                                                customEmojis2
                                                source
                                                bullet.endIndex
                                                modifiers
                                                ""
                                                (bulletRevNodes
                                                    (BulletPoint HasLeadingLineBreak bullet.items)
                                                    bullet.trailing
                                                    (flushText accText revNodes)
                                                )

                                        Nothing ->
                                            case parseStickerId (index + 1) source of
                                                ( index2, Just stickerId ) ->
                                                    discordParseLoop
                                                        customEmojis2
                                                        source
                                                        index2
                                                        modifiers
                                                        ""
                                                        (Sticker stickerId :: flushText accText revNodes)

                                                ( _, Nothing ) ->
                                                    discordParseLoop
                                                        customEmojis2
                                                        source
                                                        (index + 1)
                                                        modifiers
                                                        (accText ++ "\n")
                                                        revNodes

                else
                    -- Line breaks should terminate any open modifiers
                    finalizeResult discordModifierToSymbol accText revNodes modifiers index

            --case
            --    if List.isEmpty modifiers then
            --        extractBlockQuote source (index + 1)
            --
            --    else
            --        Nothing
            --of
            --    Just ( content, endIndex ) ->
            --        discordParseLoop
            --            source
            --            endIndex
            --            modifiers
            --            ""
            --            (BlockQuote (parseDiscordBlockQuoteContent content) :: flushText accText revNodes)
            --
            --    Nothing ->
            --        discordParseLoop source (index + 1) modifiers (accText ++ "\n") revNodes
            "\\" ->
                let
                    afterBackslash =
                        index + 1
                in
                case stringAt afterBackslash source of
                    Just nextChar ->
                        if isDiscordEscapable nextChar then
                            discordParseLoop customEmojis2 source (afterBackslash + 1) modifiers (accText ++ nextChar) revNodes

                        else
                            -- Same as in at-chat's own parser above: the backslash isn't
                            -- escaping anything, so what follows it still gets read normally
                            discordParseLoop customEmojis2 source afterBackslash modifiers (accText ++ "\\") revNodes

                    Nothing ->
                        discordParseLoop customEmojis2 source afterBackslash modifiers (accText ++ "\\") revNodes

            "<" ->
                let
                    bailOutHelper () =
                        discordParseLoop customEmojis2 source (index + 1) modifiers (accText ++ "<") revNodes
                in
                case stringAt (index + 1) source of
                    Just "@" ->
                        case tryParseDiscordMention source index of
                            Just ( userId, nextIndex ) ->
                                discordParseLoop
                                    customEmojis2
                                    source
                                    nextIndex
                                    modifiers
                                    ""
                                    (UserMention userId :: flushText accText revNodes)

                            Nothing ->
                                bailOutHelper ()

                    Just "h" ->
                        case parseUrlBody True discordModifierToSymbol modifiers (index + 1) source of
                            Ok url ->
                                let
                                    index2 =
                                        index + 1 + String.length (Url.toString url)
                                in
                                case stringAt index2 source of
                                    Just ">" ->
                                        discordParseLoop
                                            customEmojis2
                                            source
                                            (index2 + 1)
                                            modifiers
                                            ""
                                            (Hyperlink url :: flushText accText revNodes)

                                    _ ->
                                        discordParseLoop
                                            customEmojis2
                                            source
                                            (index2 + 1)
                                            modifiers
                                            ""
                                            (Hyperlink url :: flushText (accText ++ "<") revNodes)

                            Err _ ->
                                bailOutHelper ()

                    Just "a" ->
                        case stringAt (index + 2) source of
                            Just ":" ->
                                case tryParseDiscordCustomEmoji True (index + 3) source of
                                    Just ( nameAndId, nextIndex ) ->
                                        case OneToOne.second nameAndId customEmojis2 of
                                            Just emojiId ->
                                                discordParseLoop
                                                    customEmojis2
                                                    source
                                                    nextIndex
                                                    modifiers
                                                    ""
                                                    (CustomEmoji emojiId :: flushText accText revNodes)

                                            Nothing ->
                                                bailOutHelper ()

                                    Nothing ->
                                        bailOutHelper ()

                            _ ->
                                bailOutHelper ()

                    Just ":" ->
                        case tryParseDiscordCustomEmoji False (index + 2) source of
                            Just ( nameAndId, nextIndex ) ->
                                case OneToOne.second nameAndId customEmojis2 of
                                    Just emojiId ->
                                        discordParseLoop
                                            customEmojis2
                                            source
                                            nextIndex
                                            modifiers
                                            ""
                                            (CustomEmoji emojiId :: flushText accText revNodes)

                                    Nothing ->
                                        bailOutHelper ()

                            Nothing ->
                                bailOutHelper ()

                    Just "t" ->
                        case tryParseDiscordTimestamp source index of
                            Just ( time, nextIndex ) ->
                                discordParseLoop
                                    customEmojis2
                                    source
                                    nextIndex
                                    modifiers
                                    ""
                                    (Timestamp time :: flushText accText revNodes)

                            Nothing ->
                                bailOutHelper ()

                    _ ->
                        bailOutHelper ()

            "*" ->
                if String.slice index (index + 2) source == "**" then
                    let
                        afterSymbol =
                            index + 2
                    in
                    if List.head modifiers == Just DiscordIsBold then
                        closeModifier afterSymbol accText revNodes Bold (discordModifierToSymbol DiscordIsBold)

                    else if List.member DiscordIsBold modifiers then
                        finalizeResult discordModifierToSymbol accText revNodes modifiers index

                    else
                        let
                            flushed =
                                flushText accText revNodes

                            inner =
                                discordParseInner customEmojis2 source afterSymbol (DiscordIsBold :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        discordParseLoop customEmojis2 source inner.nextIndex modifiers "" newRevNodes

                else
                    let
                        afterSymbol =
                            index + 1
                    in
                    if List.head modifiers == Just DiscordIsItalic then
                        closeModifier afterSymbol accText revNodes Italic (discordModifierToSymbol DiscordIsItalic)

                    else if List.member DiscordIsItalic modifiers then
                        finalizeResult discordModifierToSymbol accText revNodes modifiers index

                    else
                        let
                            nextChar =
                                String.slice afterSymbol (afterSymbol + 1) source
                        in
                        if nextChar == "*" || nextChar == " " then
                            discordParseLoop customEmojis2 source afterSymbol modifiers (accText ++ "*") revNodes

                        else
                            let
                                flushed =
                                    flushText accText revNodes

                                inner =
                                    discordParseInner customEmojis2 source afterSymbol (DiscordIsItalic :: modifiers)

                                newRevNodes =
                                    List.foldl (\node acc -> node :: acc) flushed inner.nodes
                            in
                            discordParseLoop customEmojis2 source inner.nextIndex modifiers "" newRevNodes

            "_" ->
                if String.slice index (index + 2) source == "__" then
                    let
                        afterSymbol =
                            index + 2
                    in
                    if List.head modifiers == Just DiscordIsUnderlined then
                        closeModifier afterSymbol accText revNodes Underline (discordModifierToSymbol DiscordIsUnderlined)

                    else if List.member DiscordIsUnderlined modifiers then
                        finalizeResult discordModifierToSymbol accText revNodes modifiers index

                    else
                        let
                            flushed =
                                flushText accText revNodes

                            inner =
                                discordParseInner customEmojis2 source afterSymbol (DiscordIsUnderlined :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        discordParseLoop customEmojis2 source inner.nextIndex modifiers "" newRevNodes

                else
                    let
                        afterSymbol =
                            index + 1
                    in
                    if List.head modifiers == Just DiscordIsItalic2 then
                        closeModifier afterSymbol accText revNodes Italic (discordModifierToSymbol DiscordIsItalic2)

                    else if List.member DiscordIsItalic2 modifiers then
                        finalizeResult discordModifierToSymbol accText revNodes modifiers index

                    else
                        let
                            flushed =
                                flushText accText revNodes

                            inner =
                                discordParseInner customEmojis2 source afterSymbol (DiscordIsItalic2 :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        discordParseLoop customEmojis2 source inner.nextIndex modifiers "" newRevNodes

            "~" ->
                if (List.head modifiers /= Just DiscordIsStrikethrough) && String.slice index (index + 4) source == "~~~~" then
                    discordParseLoop customEmojis2 source (index + 4) modifiers (accText ++ "~~~~") revNodes

                else if String.slice index (index + 2) source == "~~" then
                    let
                        afterSymbol =
                            index + 2
                    in
                    if List.head modifiers == Just DiscordIsStrikethrough then
                        closeModifier afterSymbol accText revNodes Strikethrough (discordModifierToSymbol DiscordIsStrikethrough)

                    else if List.member DiscordIsStrikethrough modifiers then
                        finalizeResult discordModifierToSymbol accText revNodes modifiers index

                    else
                        let
                            flushed =
                                flushText accText revNodes

                            inner =
                                discordParseInner customEmojis2 source afterSymbol (DiscordIsStrikethrough :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        discordParseLoop customEmojis2 source inner.nextIndex modifiers "" newRevNodes

                else
                    discordParseLoop customEmojis2 source (index + 1) modifiers (accText ++ "~") revNodes

            "|" ->
                if (List.head modifiers /= Just DiscordIsSpoilered) && String.slice index (index + 4) source == "||||" then
                    discordParseLoop customEmojis2 source (index + 4) modifiers (accText ++ "||||") revNodes

                else if String.slice index (index + 2) source == "||" then
                    let
                        afterSymbol =
                            index + 2
                    in
                    if List.head modifiers == Just DiscordIsSpoilered then
                        closeModifier afterSymbol accText revNodes Spoiler (discordModifierToSymbol DiscordIsSpoilered)

                    else if List.member DiscordIsSpoilered modifiers then
                        finalizeResult discordModifierToSymbol accText revNodes modifiers index

                    else
                        let
                            flushed =
                                flushText accText revNodes

                            inner =
                                discordParseInner customEmojis2 source afterSymbol (DiscordIsSpoilered :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        discordParseLoop customEmojis2 source inner.nextIndex modifiers "" newRevNodes

                else
                    discordParseLoop customEmojis2 source (index + 1) modifiers (accText ++ "|") revNodes

            "`" ->
                case ( stringAtRange index 3 source, findSubstring source (index + 3) "```" ) of
                    ( Just "```", Just closeIndex ) ->
                        let
                            content =
                                String.slice (index + 3) closeIndex source

                            ( language, codeContent ) =
                                parseCodeBlockContent content
                        in
                        case String.Nonempty.fromString codeContent of
                            Just _ ->
                                discordParseLoop
                                    customEmojis2
                                    source
                                    (closeIndex + 3)
                                    modifiers
                                    ""
                                    (CodeBlock language codeContent :: flushText accText revNodes)

                            Nothing ->
                                discordParseLoop
                                    customEmojis2
                                    source
                                    (closeIndex + 3)
                                    modifiers
                                    (accText ++ "``````")
                                    revNodes

                    _ ->
                        case findSingleBacktick source (index + 1) of
                            Just closeIndex ->
                                let
                                    content =
                                        String.slice (index + 1) closeIndex source
                                in
                                case ( String.Nonempty.fromString content, String.contains "\n" content ) of
                                    ( Just a, False ) ->
                                        discordParseLoop
                                            customEmojis2
                                            source
                                            (closeIndex + 1)
                                            modifiers
                                            ""
                                            (InlineCode (String.Nonempty.head a) (String.Nonempty.tail a) :: flushText accText revNodes)

                                    _ ->
                                        discordParseLoop customEmojis2 source (index + 1) modifiers (accText ++ "`") revNodes

                            Nothing ->
                                discordParseLoop customEmojis2 source (index + 1) modifiers (accText ++ "`") revNodes

            "h" ->
                case parseUrlBody False discordModifierToSymbol modifiers index source of
                    Ok url ->
                        discordParseLoop
                            customEmojis2
                            source
                            (index + String.length (Url.toString url))
                            modifiers
                            ""
                            (Hyperlink url :: flushText accText revNodes)

                    Err errText ->
                        let
                            unescaped : { text : String, consumed : Int }
                            unescaped =
                                unescapeDiscordText errText
                        in
                        discordParseLoop
                            customEmojis2
                            source
                            (index + unescaped.consumed)
                            modifiers
                            (accText ++ unescaped.text)
                            revNodes

            "[" ->
                case parseMarkdownLink True source (index + 1) of
                    Just ( alias, url, nextIndex ) ->
                        discordParseLoop
                            customEmojis2
                            source
                            nextIndex
                            modifiers
                            ""
                            (MarkdownLink alias url :: flushText accText revNodes)

                    Nothing ->
                        discordParseLoop customEmojis2 source (index + 1) modifiers (accText ++ "[") revNodes

            _ ->
                let
                    nextIndex =
                        skipDiscordNormalChars source (index + 1) (String.length source)
                in
                discordParseLoop
                    customEmojis2
                    source
                    nextIndex
                    modifiers
                    (accText ++ String.slice index nextIndex source)
                    revNodes


toDiscord :
    OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
    -> Nonempty (RichText (Discord.Id Discord.UserId))
    -> Result Int String
toDiscord customEmojis2 content =
    let
        text : String
        text =
            toDiscordHelper customEmojis2 (List.Nonempty.toList content)
    in
    if String.length text > maxLength then
        Err (maxLength - String.length text)

    else
        Ok text


discordCharsLeft :
    OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
    -> Maybe (Nonempty (RichText (Discord.Id Discord.UserId)))
    -> Int
discordCharsLeft customEmojis2 richText =
    case richText of
        Just richText2 ->
            case toDiscord customEmojis2 richText2 of
                Ok text ->
                    maxLength - String.length text

                Err charsLeft ->
                    charsLeft

        Nothing ->
            maxLength


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool, id : Discord.Id Discord.CustomEmojiId, name : EmojiName }


toDiscordHelper :
    OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
    -> List (RichText (Discord.Id Discord.UserId))
    -> String
toDiscordHelper customEmojis2 content =
    List.map
        (\item ->
            case item of
                UserMention discordUserId ->
                    "<@!" ++ Discord.idToString discordUserId ++ ">"

                NormalText char string ->
                    escapeDiscordText (String.cons char string)

                Bold nonempty ->
                    "**" ++ toDiscordHelper customEmojis2 (List.Nonempty.toList nonempty) ++ "**"

                Italic nonempty ->
                    "*" ++ toDiscordHelper customEmojis2 (List.Nonempty.toList nonempty) ++ "*"

                Underline nonempty ->
                    "__" ++ toDiscordHelper customEmojis2 (List.Nonempty.toList nonempty) ++ "__"

                Strikethrough nonempty ->
                    "~~" ++ toDiscordHelper customEmojis2 (List.Nonempty.toList nonempty) ++ "~~"

                Spoiler nonempty ->
                    "||" ++ toDiscordHelper customEmojis2 (List.Nonempty.toList nonempty) ++ "||"

                BlockQuote hasLeadingLineBreak list ->
                    (case hasLeadingLineBreak of
                        HasLeadingLineBreak ->
                            "\n"

                        NoLeadingLineBreak ->
                            ""
                    )
                        ++ "> "
                        ++ String.replace "\n" "\n> " (toDiscordHelper customEmojis2 list)

                Heading level hasLeadingLineBreak nonempty ->
                    let
                        prefix : String
                        prefix =
                            (case hasLeadingLineBreak of
                                HasLeadingLineBreak ->
                                    "\n"

                                NoLeadingLineBreak ->
                                    ""
                            )
                                ++ headingLevelToMarker level
                    in
                    prefix ++ toDiscordHelper customEmojis2 (List.Nonempty.toList nonempty)

                Hyperlink data ->
                    Url.toString data

                MarkdownLink alias url ->
                    "[" ++ String.Nonempty.toString alias ++ "](" ++ Url.toString url ++ ")"

                InlineCode char string ->
                    "`" ++ String.cons char string ++ "`"

                CodeBlock language string ->
                    "```"
                        ++ (case language of
                                Language language2 ->
                                    String.Nonempty.toString language2 ++ "\n"

                                NoLanguage ->
                                    ""
                           )
                        ++ string
                        ++ "```"

                AttachedFile _ ->
                    ""

                EscapedChar char ->
                    escapeDiscordText (escapedCharToString char)

                Sticker _ ->
                    ""

                CustomEmoji id ->
                    case OneToOne.first id customEmojis2 of
                        Just discordIdAndName ->
                            "<:"
                                ++ CustomEmoji.emojiNameToString discordIdAndName.name
                                ++ ":"
                                ++ Discord.idToString discordIdAndName.id
                                ++ ">"

                        Nothing ->
                            "<missing:123123123>"

                BulletPoint hasLeadingLineBreak items ->
                    (case hasLeadingLineBreak of
                        HasLeadingLineBreak ->
                            "\n"

                        NoLeadingLineBreak ->
                            ""
                    )
                        ++ (List.Nonempty.toList items
                                |> List.map (\bulletItem -> "* " ++ toDiscordHelper customEmojis2 bulletItem)
                                |> String.join "\n"
                           )

                Timestamp time ->
                    timestampToDiscordString time
        )
        content
        |> String.concat


customEmojisFromDiscord : String -> List DiscordCustomEmojiIdAndName
customEmojisFromDiscord text =
    List.filterMap
        (\index -> tryParseDiscordCustomEmoji False (index + 2) text |> Maybe.map Tuple.first)
        (String.indexes "<:" text)
        ++ List.filterMap
            (\index -> tryParseDiscordCustomEmoji True (index + 3) text |> Maybe.map Tuple.first)
            (String.indexes "<a:" text)


{-| A character at-chat reads as plain text can still be formatting to Discord, so every one
of them is hidden behind a backslash on the way out, and `isDiscordEscapable` takes the
backslashes off again when the message is read back.

This hides more than Discord strictly needs — a lone `_` was never going to be italics — but
knowing which ones matter means knowing Discord's grammar exactly, and nothing at-chat can
see says what that grammar is. The extra backslashes don't change how a message reads in
Discord, so they stay.

-}
escapeDiscordText : String -> String
escapeDiscordText text =
    String.replace "\\" "\\\\" text
        |> String.replace "_" "\\_"
        |> String.replace "*" "\\*"
        |> String.replace "`" "\\`"
        |> String.replace ">" "\\>"
        |> String.replace "@" "\\@"
        |> String.replace "~" "\\~"
        |> String.replace "|" "\\|"


discordParseInner :
    OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
    -> String
    -> Int
    -> List DiscordModifiers
    -> { nodes : List (RichText (Discord.Id Discord.UserId)), nextIndex : Int }
discordParseInner customEmojis2 source index modifiers =
    discordParseLoop customEmojis2 source index modifiers "" []


parseDiscordBlockQuoteContent : OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId) -> String -> List (RichText (Discord.Id Discord.UserId))
parseDiscordBlockQuoteContent customEmojis2 content =
    case discordParseLoop customEmojis2 content 0 [] "" [] |> .nodes |> List.Nonempty.fromList of
        Just nonempty ->
            normalize nonempty |> List.Nonempty.toList

        Nothing ->
            []


parseDiscordHeadingContent : OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId) -> NonemptyString -> Nonempty (RichText (Discord.Id Discord.UserId))
parseDiscordHeadingContent customEmojis2 content =
    case discordParseLoop customEmojis2 (String.Nonempty.toString content) 0 [] "" [] |> .nodes |> List.Nonempty.fromList of
        Just nonempty ->
            normalize nonempty

        Nothing ->
            Nonempty (NormalText (String.Nonempty.head content) (String.Nonempty.tail content)) []


tryParseDiscordCustomEmoji : Bool -> Int -> String -> Maybe ( DiscordCustomEmojiIdAndName, Int )
tryParseDiscordCustomEmoji isAnimated index source =
    case ( findChar source index (String.length source) ':', findChar source index (String.length source) '>' ) of
        ( Just nameEnd, Just idEnd ) ->
            if nameEnd < idEnd then
                case
                    ( String.slice index nameEnd source |> CustomEmoji.emojiNameFromString
                    , String.slice (nameEnd + 1) idEnd source |> Discord.idFromString
                    )
                of
                    ( Ok name, Just discordId ) ->
                        Just ( { isAnimated = isAnimated, id = discordId, name = name }, idEnd + 1 )

                    _ ->
                        Nothing

            else
                Nothing

        _ ->
            Nothing


tryParseDiscordMention : String -> Int -> Maybe ( Discord.Id Discord.UserId, Int )
tryParseDiscordMention source index =
    let
        len =
            String.length source

        afterAt =
            index + 2

        afterBang =
            if afterAt < len && String.slice afterAt (afterAt + 1) source == "!" then
                afterAt + 1

            else
                afterAt

        digitEnd =
            skipDigits source afterBang len
    in
    if digitEnd > afterBang && digitEnd < len && String.slice digitEnd (digitEnd + 1) source == ">" then
        case UInt64.fromString (String.slice afterBang digitEnd source) of
            Just discordUserId ->
                Just ( Discord.idFromUInt64 discordUserId, digitEnd + 1 )

            Nothing ->
                Nothing

    else
        Nothing


{-| Discord's timestamp syntax: `<t:1786013400>`, or `<t:1786013400:f>` where the trailing
letter hints at the format Discord should show it in. at-chat picks its own format, so the
hint is read past and thrown away.

`index` points at the opening `<`.

-}
tryParseDiscordTimestamp : String -> Int -> Maybe ( TimeInMinutes, Int )
tryParseDiscordTimestamp source index =
    let
        len : Int
        len =
            String.length source

        afterColon : Int
        afterColon =
            index + 3

        digitEnd : Int
        digitEnd =
            skipDigits source afterColon len
    in
    if stringAt (index + 1) source == Just "t" && stringAt (index + 2) source == Just ":" && digitEnd > afterColon then
        case ( String.toInt (String.slice afterColon digitEnd source), stringAt digitEnd source ) of
            ( Just seconds, Just ">" ) ->
                Just ( TimeInMinutes.fromMinutes (seconds // 60), digitEnd + 1 )

            ( Just seconds, Just ":" ) ->
                if stringAt (digitEnd + 2) source == Just ">" then
                    Just ( TimeInMinutes.fromMinutes (seconds // 60), digitEnd + 3 )

                else
                    Nothing

            _ ->
                Nothing

    else
        Nothing


skipDiscordNormalChars : String -> Int -> Int -> Int
skipDiscordNormalChars source index len =
    if index >= len then
        index

    else
        let
            c =
                String.slice index (index + 1) source
        in
        if c == "<" || c == "h" || c == "`" || c == "\\" || c == "*" || c == "_" || c == "~" || c == "|" || c == "[" || c == "\n" then
            index

        else
            skipDiscordNormalChars source (index + 1) len
