module RichText exposing
    ( DiscordCustomEmojiIdAndName
    , Domain(..)
    , EscapedChar(..)
    , HasLeadingLineBreak(..)
    , HeadingLevel(..)
    , Language(..)
    , Modifiers(..)
    , RichText(..)
    , RichTextState
    , attachedFilePrefix
    , attachedFileSuffix
    , attachments
    , customEmojisFromDiscord
    , discordCharsLeft
    , domainToString
    , emptyPlaceholder
    , escapedCharToString
    , fromDiscord
    , fromNonemptyString
    , hyperlinks
    , maxLength
    , mentionsUser
    , preview
    , removeAttachedFile
    , spoilerAttachedFile
    , stickers
    , stringToStickers
    , textInputView
    , toDiscord
    , toString
    , toStringWithGetter
    , unspoilerAttachedFile
    , urlToDomain
    , view
    )

import Array exposing (Array)
import Basics.Extra
import Coord exposing (Coord)
import CustomEmoji exposing (CustomEmojiData, EmojiName)
import Dict exposing (Dict)
import Discord exposing (EmbedType(..))
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Time as Time
import Embed exposing (Embed(..), EmbedData)
import FileName
import FileStatus exposing (FileData, FileId)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Icons
import Id exposing (CustomEmojiId, Id, StickerId)
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import MyUi
import NonemptyExtra
import OneToOne exposing (OneToOne)
import PersonName exposing (PersonName)
import Range exposing (Range)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Set exposing (Set)
import Sticker exposing (StickerData)
import String.Nonempty exposing (NonemptyString(..))
import UInt64
import Url exposing (Protocol(..), Url)


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

                CustomEmoji id ->
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

                CustomEmoji id ->
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

                CustomEmoji id ->
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

                CustomEmoji id ->
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

                CustomEmoji id ->
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

                CustomEmoji id ->
                    []
        )
        (List.Nonempty.toList nonempty)


toStringWithGetter : (a -> String) -> Bool -> SeqDict userId a -> Nonempty (RichText userId) -> String
toStringWithGetter userToString emojisForStickersAndAttachments users nonempty =
    toStringHelper userToString emojisForStickersAndAttachments users (List.Nonempty.toList nonempty)


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


toString : Bool -> SeqDict userId { a | name : PersonName } -> Nonempty (RichText userId) -> String
toString emojisForStickersAndAttachments users nonempty =
    toStringHelper
        (\user -> PersonName.toString user.name)
        emojisForStickersAndAttachments
        users
        (List.Nonempty.toList nonempty)


maxLength : number
maxLength =
    2000


toStringHelper : (a -> String) -> Bool -> SeqDict userId a -> List (RichText userId) -> String
toStringHelper userToString emojisForStickersAndAttachments users list =
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
                        ++ toStringHelper userToString emojisForStickersAndAttachments users (List.Nonempty.toList a)
                        ++ "*"

                Italic a ->
                    "_"
                        ++ toStringHelper userToString emojisForStickersAndAttachments users (List.Nonempty.toList a)
                        ++ "_"

                Underline a ->
                    "__"
                        ++ toStringHelper userToString emojisForStickersAndAttachments users (List.Nonempty.toList a)
                        ++ "__"

                Strikethrough a ->
                    "~~"
                        ++ toStringHelper userToString emojisForStickersAndAttachments users (List.Nonempty.toList a)
                        ++ "~~"

                Spoiler a ->
                    "||"
                        ++ toStringHelper userToString emojisForStickersAndAttachments users (List.Nonempty.toList a)
                        ++ "||"

                BlockQuote hasLeadingLineBreak a ->
                    blockQuoteToString
                        hasLeadingLineBreak
                        (toStringHelper userToString emojisForStickersAndAttachments users a)

                Heading level hasLeadingLineBreak a ->
                    headingToString
                        hasLeadingLineBreak
                        level
                        (toStringHelper userToString emojisForStickersAndAttachments users (List.Nonempty.toList a))

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
        )
        list
        |> String.concat


fromNonemptyString : SeqDict userId { a | name : PersonName } -> NonemptyString -> Nonempty (RichText userId)
fromNonemptyString users string =
    let
        source =
            String.Nonempty.toString string

        ( startIndex, startRevNodes ) =
            case extractBlockQuote source 0 of
                Just ( content, endIndex ) ->
                    ( endIndex, [ BlockQuote NoLeadingLineBreak (parseBlockQuoteContent users content) ] )

                Nothing ->
                    case extractHeading source 0 of
                        Just ( level, content, endIndex ) ->
                            ( endIndex, [ Heading level NoLeadingLineBreak (parseHeadingContent users content) ] )

                        Nothing ->
                            ( 0, [] )

        result =
            parseLoop source startIndex users [] "" startRevNodes
    in
    case List.Nonempty.fromList result.nodes of
        Just nonempty ->
            normalize nonempty

        Nothing ->
            Nonempty (normalTextFromNonempty string) []


parseBlockQuoteContent : SeqDict userId { a | name : PersonName } -> String -> List (RichText userId)
parseBlockQuoteContent users content =
    case parseLoop content 0 users [] "" [] |> .nodes |> List.Nonempty.fromList of
        Just nonempty ->
            normalize nonempty |> List.Nonempty.toList

        Nothing ->
            []


parseHeadingContent : SeqDict userId { a | name : PersonName } -> NonemptyString -> Nonempty (RichText userId)
parseHeadingContent users content =
    case parseLoop (String.Nonempty.toString content) 0 users [] "" [] |> .nodes |> List.Nonempty.fromList of
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


discordEscapableChars : Set String
discordEscapableChars =
    Set.fromList [ "\\", "*", ">", "`", "~", "@" ]


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


parseInner : String -> Int -> SeqDict userId { a | name : PersonName } -> List Modifiers -> { nodes : List (RichText userId), nextIndex : Int }
parseInner source index users modifiers =
    parseLoop source index users modifiers "" []


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
                    ( index + 1
                    , case stringAt (index + 1) source of
                        Just "\u{200B}" ->
                            Nothing

                        Just "\u{200C}" ->
                            Nothing

                        Just "\u{200D}" ->
                            Nothing

                        Just "\u{2060}" ->
                            Nothing

                        _ ->
                            Just (Id.fromInt 0)
                    )

                "\u{200C}" ->
                    parseCustomEmojiIdHelper 1 (index + 1) source |> Tuple.mapSecond Just

                "\u{200D}" ->
                    parseCustomEmojiIdHelper 2 (index + 1) source |> Tuple.mapSecond Just

                "\u{2060}" ->
                    parseCustomEmojiIdHelper 3 (index + 1) source |> Tuple.mapSecond Just

                _ ->
                    ( index, Nothing )

        Nothing ->
            ( index, Nothing )


parseCustomEmojiIdHelper : Int -> Int -> String -> ( Int, Id CustomEmojiId )
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

                _ ->
                    ( index, Id.fromInt id )

        Nothing ->
            ( index, Id.fromInt id )


stringToStickers : String -> List ( Range, Maybe (Id StickerId) )
stringToStickers text =
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
                ( { start = index, end = endIndex }, stickerId ) :: shouldRemove
            )
            []
        |> List.sortBy (\( range, _ ) -> -range.start)


parseLoop :
    String
    -> Int
    -> SeqDict userId { a | name : PersonName }
    -> List Modifiers
    -> String
    -> List (RichText userId)
    -> { nodes : List (RichText userId), nextIndex : Int }
parseLoop source index users modifiers accText revNodes =
    if index >= String.length source then
        finalizeResult modifierToSymbol accText revNodes modifiers index

    else
        case String.slice index (index + 1) source of
            "❓" ->
                case parseCustomEmojiId (index + 1) source of
                    ( index2, Just customEmojiId ) ->
                        parseLoop source index2 users modifiers "" (CustomEmoji customEmojiId :: flushText accText revNodes)

                    ( _, Nothing ) ->
                        parseLoop source (index + 1) users modifiers (accText ++ "❓") revNodes

            "\n" ->
                if List.isEmpty modifiers then
                    case extractBlockQuote source (index + 1) of
                        Just ( content, endIndex ) ->
                            parseLoop
                                source
                                endIndex
                                users
                                modifiers
                                ""
                                (BlockQuote
                                    HasLeadingLineBreak
                                    (parseBlockQuoteContent users content)
                                    :: flushText accText revNodes
                                )

                        Nothing ->
                            case extractHeading source (index + 1) of
                                Just ( level, content, endIndex ) ->
                                    parseLoop
                                        source
                                        endIndex
                                        users
                                        modifiers
                                        ""
                                        (Heading
                                            level
                                            HasLeadingLineBreak
                                            (parseHeadingContent users content)
                                            :: flushText accText revNodes
                                        )

                                Nothing ->
                                    case parseStickerId (index + 1) source of
                                        ( index2, Just stickerId ) ->
                                            parseLoop source index2 users modifiers "" (Sticker stickerId :: flushText accText revNodes)

                                        ( _, Nothing ) ->
                                            parseLoop source (index + 1) users modifiers (accText ++ "\n") revNodes

                else
                    -- Line breaks should terminate any open modifiers
                    finalizeResult modifierToSymbol accText revNodes modifiers index

            "\\" ->
                let
                    afterBackslash =
                        index + 1
                in
                case stringAt afterBackslash source of
                    Just nextChar ->
                        case Dict.get nextChar charToEscaped of
                            Just escaped ->
                                parseLoop source (afterBackslash + 1) users modifiers "" (EscapedChar escaped :: flushText accText revNodes)

                            Nothing ->
                                parseLoop source (afterBackslash + 1) users modifiers (accText ++ "\\" ++ nextChar) revNodes

                    Nothing ->
                        parseLoop source afterBackslash users modifiers (accText ++ "\\") revNodes

            "@" ->
                let
                    afterAt =
                        index + 1

                    remaining =
                        String.slice afterAt (String.length source) source
                in
                case tryMatchUser users remaining of
                    Just ( userId, matchLen ) ->
                        parseLoop source (afterAt + matchLen) users modifiers "" (UserMention userId :: flushText accText revNodes)

                    Nothing ->
                        parseLoop source afterAt users modifiers (accText ++ "@") revNodes

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
                        parseLoop source afterSymbol users modifiers (accText ++ "*") revNodes

                    else
                        let
                            flushed =
                                flushText accText revNodes

                            inner =
                                parseInner source afterSymbol users (IsBold :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        parseLoop source inner.nextIndex users modifiers "" newRevNodes

            "_" ->
                if String.slice index (index + 4) source == "____" then
                    parseLoop source (index + 4) users modifiers (accText ++ "____") revNodes

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
                                parseInner source afterSymbol users (IsUnderlined :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        parseLoop source inner.nextIndex users modifiers "" newRevNodes

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
                                parseInner source afterSymbol users (IsItalic :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        parseLoop source inner.nextIndex users modifiers "" newRevNodes

            "~" ->
                if (List.head modifiers /= Just IsStrikethrough) && String.slice index (index + 4) source == "~~~~" then
                    parseLoop source (index + 4) users modifiers (accText ++ "~~~~") revNodes

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
                                parseInner source afterSymbol users (IsStrikethrough :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        parseLoop source inner.nextIndex users modifiers "" newRevNodes

                else
                    parseLoop source (index + 1) users modifiers (accText ++ "~") revNodes

            "|" ->
                if (List.head modifiers /= Just IsSpoilered) && String.slice index (index + 4) source == "||||" then
                    parseLoop source (index + 4) users modifiers (accText ++ "||||") revNodes

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
                                parseInner source afterSymbol users (IsSpoilered :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        parseLoop source inner.nextIndex users modifiers "" newRevNodes

                else
                    parseLoop source (index + 1) users modifiers (accText ++ "|") revNodes

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
                                parseLoop source (closeIndex + 3) users modifiers "" (CodeBlock language codeContent :: flushText accText revNodes)

                            Nothing ->
                                parseLoop source (closeIndex + 3) users modifiers (accText ++ "``````") revNodes

                    _ ->
                        case findSingleBacktick source (index + 1) of
                            Just closeIndex ->
                                let
                                    content =
                                        String.slice (index + 1) closeIndex source
                                in
                                case ( String.Nonempty.fromString content, String.contains "\n" content ) of
                                    ( Just a, False ) ->
                                        parseLoop source (closeIndex + 1) users modifiers "" (InlineCode (String.Nonempty.head a) (String.Nonempty.tail a) :: flushText accText revNodes)

                                    _ ->
                                        parseLoop source (index + 1) users modifiers (accText ++ "`") revNodes

                            Nothing ->
                                parseLoop source (index + 1) users modifiers (accText ++ "`") revNodes

            "h" ->
                case parseUrlBody False modifierToSymbol modifiers index source of
                    Ok url ->
                        parseLoop
                            source
                            (index + String.length (Url.toString url))
                            users
                            modifiers
                            ""
                            (Hyperlink url :: flushText accText revNodes)

                    Err errText ->
                        parseLoop
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
                            parseLoop source nextIndex users modifiers "" (AttachedFile (Id.fromInt fileId) :: flushText accText revNodes)

                        Nothing ->
                            parseLoop source (index + 1) users modifiers (accText ++ "[") revNodes

                else
                    case parseMarkdownLink source (index + 1) of
                        Just ( alias, url, nextIndex ) ->
                            parseLoop source nextIndex users modifiers "" (MarkdownLink alias url :: flushText accText revNodes)

                        Nothing ->
                            parseLoop source (index + 1) users modifiers (accText ++ "[") revNodes

            _ ->
                let
                    nextIndex =
                        skipNormalChars source (index + 1)
                in
                parseLoop source nextIndex users modifiers (accText ++ String.slice index nextIndex source) revNodes


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

                ( trimIdx, _ ) =
                    String.foldr
                        (\char ( idx, stop ) ->
                            if stop then
                                ( idx, True )

                            else if char == '.' || char == ')' || char == ',' || char == '"' || char == ':' || Set.member char modifierChars then
                                ( idx - 1, False )

                            else if startedWithAngleBracket && char == '>' then
                                ( idx - 1, True )

                            else
                                ( idx, True )
                        )
                        ( urlBodyLen, False )
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


parseMarkdownLink : String -> Int -> Maybe ( NonemptyString, Url, Int )
parseMarkdownLink source index =
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
        if c == "[" || c == "@" || c == "h" || c == "`" || c == "\\" || c == "*" || c == "_" || c == "~" || c == "|" || c == "\n" || c == "❓" then
            index

        else
            skipNormalChars source (index + 1)


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

                CustomEmoji id ->
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


view :
    HtmlId
    -> Int
    -> (Url -> msg)
    -> (Int -> msg)
    -> Config a userId
    -> Array Embed
    -> Nonempty (RichText userId)
    -> List (Html msg)
view htmlIdPrefix containerWidth onPressLink onPressSpoiler config embeds nonempty =
    viewHelper
        False
        (ShowLargeContent containerWidth)
        (Just ( htmlIdPrefix, onPressSpoiler ))
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
    }


type alias PreviewConfig a userId =
    { domainWhitelist : SeqSet Domain
    , revealedSpoilers : SeqSet Int
    , users : SeqDict userId { a | name : PersonName }
    , attachedFiles : SeqDict (Id FileId) FileData
    , customEmojis : SeqDict (Id CustomEmojiId) CustomEmojiData
    }


normalTextView : String -> RichTextState -> List (Html msg)
normalTextView text state =
    [ Html.span
        [ htmlAttrIf state.italic (Html.Attributes.style "font-style" "italic")
        , htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
        , htmlAttrIf state.bold (Html.Attributes.style "font-weight" "700")
        , htmlAttrIf state.strikethrough (Html.Attributes.style "text-decoration" "line-through")
        , htmlAttrIf state.spoiler (Html.Attributes.style "opacity" "0")
        ]
        [ Html.text text ]
    ]


viewHelper :
    Bool
    -> ShowLargeContent
    -> Maybe ( HtmlId, Int -> msg )
    -> (Url -> msg)
    -> Int
    -> RichTextState
    -> Config a userId
    -> Array Embed
    -> Int
    -> Nonempty (RichText userId)
    -> ( ( Bool, Int ), Int, List (Html msg) )
viewHelper dropNextLineBreak showLargeContent maybePressedSpoiler onPressLink spoilerIndex state config embeds embedIndex nonempty =
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
                                            [ Html.Attributes.style "background" "rgb(30,30,30)" ]

                                        else
                                            [ Html.Attributes.style "cursor" "pointer"
                                            , Html.Attributes.style "background" "rgb(0,0,0)"
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
                                        [ Html.Attributes.style "border-left" (String.fromInt borderLeft ++ "px solid rgb(80,120,200)")
                                        , Html.Attributes.style "padding" ("2px " ++ String.fromInt sidePadding ++ "px")
                                        ]
                                        list2

                                NoLargeContent ->
                                    Html.span
                                        [ Html.Attributes.style "border-left" (String.fromInt borderLeft ++ "px solid rgb(80,120,200)")
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
                                                    onPressLink
                                                    containerWidth
                                                    config.domainWhitelist
                                                    config.animationMode
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
                                    , Html.Attributes.style "color" "rgb(66,133,244)"
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
                                , Html.Attributes.style "background-color" "rgb(90,100,120)"
                                , Html.Attributes.style "border" "rgb(55,61,73) solid 1px"
                                , Html.Attributes.style "padding" "0 4px 0 4px"
                                , Html.Attributes.style "border-radius" "4px"
                                , Html.Attributes.style "font-family" "monospace"
                                ]
                                [ Html.text (String.cons char rest) ]
                           ]
                    )

                CodeBlock _ text ->
                    case showLargeContent of
                        ShowLargeContent _ ->
                            ( ( True, spoilerIndex2 )
                            , embedIndex2
                            , currentList
                                ++ [ Html.div
                                        [ Html.Attributes.style
                                            "background-color"
                                            (if state.spoiler then
                                                "rgb(0,0,0)"

                                             else
                                                "rgb(90,100,120)"
                                            )
                                        , Html.Attributes.style "border" "rgb(55,61,73) solid 1px"
                                        , Html.Attributes.style "padding" "0 4px 0 4px"
                                        , Html.Attributes.style "border-radius" "4px"
                                        , Html.Attributes.style "font-family" "monospace"
                                        ]
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
                                    currentList
                                        ++ [ case fileData.imageMetadata of
                                                Just { imageSize } ->
                                                    let
                                                        ( width, height ) =
                                                            actualImageSize FileStatus.imageMaxHeight containerWidth2 imageSize
                                                    in
                                                    if state.spoiler then
                                                        Html.div
                                                            [ Html.Attributes.style "width" (String.fromInt (round width) ++ "px")
                                                            , Html.Attributes.style "height" (String.fromInt (round height) ++ "px")
                                                            , Html.Attributes.style "display" "block"
                                                            , Html.Attributes.style "background-color" "rgb(0,0,0)"
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
                                                        in
                                                        Html.a
                                                            [ Html.Attributes.href fileUrl
                                                            , Html.Attributes.target "_blank"
                                                            , Html.Attributes.rel "noreferrer"
                                                            , Html.Attributes.style "width" (String.fromInt (round width) ++ "px")
                                                            , Html.Attributes.style "display" "block"
                                                            ]
                                                            [ Html.img
                                                                [ Html.Attributes.src thumbnailUrl
                                                                , Html.Attributes.style "display" "block"
                                                                , Html.Attributes.width (round width)
                                                                , Html.Attributes.height (round height)
                                                                ]
                                                                []
                                                            ]

                                                _ ->
                                                    fileDownloadView state.spoiler fileData
                                           ]

                                Nothing ->
                                    currentList ++ [ Icons.image ]
                            )

                        NoLargeContent ->
                            ( ( False, spoilerIndex2 ), embedIndex2, currentList ++ [ Icons.image ] )

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
                            ( ( False, spoilerIndex2 ), embedIndex2, currentList ++ [ Icons.image ] )

                CustomEmoji id ->
                    ( ( False, spoilerIndex2 )
                    , embedIndex2
                    , currentList ++ [ CustomEmoji.view id config.customEmojis config.animationMode ]
                    )
        )
        ( ( dropNextLineBreak, spoilerIndex ), embedIndex, [] )
        (List.Nonempty.toList nonempty)


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
        , Html.Attributes.style "border-radius" "4px"
        , Html.Attributes.style "overflow" "hidden"
        ]
        [ Html.div
            [ Html.Attributes.style "width" (String.fromInt embedContainerLeftBorderWidth ++ "px")
            , Html.Attributes.style "flex-shrink" "0"
            , Html.Attributes.style "background-color" "rgb(80,120,200)"
            ]
            []
        , Html.div
            [ Html.Attributes.style "background-color" (MyUi.colorToStyle MyUi.background2)
            , Html.Attributes.style "padding" ("8px " ++ String.fromInt embedContainerPaddingX ++ "px")
            , Html.Attributes.style "min-width" "0"
            , Html.Attributes.style "flex" "1"
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
                :: attributes
            )
            content

    else
        Html.span
            (Html.Events.onClick (onLinkPress url)
                :: Html.Attributes.style "cursor" "pointer"
                :: Html.Attributes.style "color" (MyUi.colorToStyle MyUi.textLinkColorOnDarkBackground)
                :: attributes
            )
            content


embedView : (Url -> msg) -> Int -> SeqSet Domain -> Sticker.AnimationMode -> Url -> EmbedData -> Html msg
embedView onPressLink containerWidth domainWhitelist playAnimation url embed =
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

                        width2 =
                            String.fromFloat width ++ "px"

                        height2 =
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
                    in
                    if isAnimatedImage then
                        Sticker.animatedImageView width2 height2 imageData.url playAnimation |> Just

                    else
                        Html.img
                            [ Html.Attributes.src imageData.url
                            , Html.Attributes.style "width" width2
                            , Html.Attributes.style "height" height2
                            , Html.Attributes.style "border-radius" "4px"
                            , Html.Attributes.style "margin-top" "8px"
                            , Html.Attributes.style "display" "block"
                            ]
                            []
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
                        [ Html.text (formatPosix createdAt) ]
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


formatPosix : Time.Posix -> String
formatPosix time =
    MyUi.datestamp time


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
        , Html.Attributes.style "border-left" "solid 5px rgb(80,120,200)"
        , Html.Attributes.style "padding-right" "4px"
        ]
        [ Html.img
            [ Html.Attributes.style "width" "1em"
            , Html.Attributes.style "height" "1em"
            , Html.Attributes.style "border-radius" "2px"
            , Html.Attributes.style "transform" "translateY(0.125em)"
            , Html.Attributes.style "padding" "0 4px 0 4px"
            , Html.Attributes.src (favicon url)
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


fileDownloadView : Bool -> FileData -> Html msg
fileDownloadView isSpoilered fileData =
    let
        fileUrl =
            FileStatus.fileUrl fileData.contentType fileData.fileHash
    in
    Html.a
        [ Html.Attributes.style "max-width" "284px"
        , Html.Attributes.style
            "background-color"
            (if isSpoilered then
                "rgb(0,0,0)"

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
    SeqDict userId { a | name : PersonName }
    -> SeqDict (Id FileId) b
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> SeqDict (Id StickerId) StickerData
    -> Maybe Range
    -> Nonempty (RichText userId)
    -> List (Html msg)
textInputView users attachedFiles customEmojis stickers2 selection nonempty =
    textInputViewHelper
        { underline = False, italic = False, bold = False, strikethrough = False, spoiler = False }
        users
        attachedFiles
        customEmojis
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
    RichTextState
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
textInputViewHelper state allUsers attachedFiles customEmojis stickers2 index selection list inBlockQuote output =
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
                                    [ Html.Attributes.style "color" "rgb(215,235,255)"
                                    , Html.Attributes.style "background-color" "rgba(57,77,255,0.5)"
                                    , Html.Attributes.style "border-radius" "2px"
                                    ]
                                    [ Html.text text ]
                                )
                                output2
                            )

                        Nothing ->
                            ( index2 + 1, output2 )

                NormalText char text ->
                    let
                        text2 =
                            String.cons char text

                        helper text4 =
                            Html.span
                                [ htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                                , htmlAttrIf state.bold (Html.Attributes.style "text-shadow" "0.7px 0px 0px white")
                                , htmlAttrIf state.strikethrough (Html.Attributes.style "text-decoration" "line-through")
                                , htmlAttrIf state.spoiler (Html.Attributes.style "background-color" "rgb(0,0,0)")
                                ]
                                [ Html.text text4 ]
                    in
                    ( index2 + String.length text2
                    , Array.append
                        output2
                        (if inBlockQuote then
                            List.map helper (String.split "\n" text2)
                                |> List.intersperse (formatText "\n> ")
                                |> Array.fromList

                         else
                            Array.fromList [ Html.text text2 ]
                        )
                    )

                Italic nonempty2 ->
                    let
                        ( index3, output3 ) =
                            textInputViewHelper
                                { state | italic = True }
                                allUsers
                                attachedFiles
                                customEmojis
                                stickers2
                                (index2 + 1)
                                selection
                                (List.Nonempty.toList nonempty2)
                                inBlockQuote
                                (Array.push (formatText "_") output2)
                    in
                    ( index3 + 1, Array.push (formatText "_") output3 )

                Underline nonempty2 ->
                    let
                        ( index3, output3 ) =
                            textInputViewHelper
                                { state | underline = True }
                                allUsers
                                attachedFiles
                                customEmojis
                                stickers2
                                (index2 + 2)
                                selection
                                (List.Nonempty.toList nonempty2)
                                inBlockQuote
                                (Array.push (formatText "__") output2)
                    in
                    ( index3 + 2, Array.push (formatText "__") output3 )

                Bold nonempty2 ->
                    let
                        ( index3, output3 ) =
                            textInputViewHelper
                                { state | bold = True }
                                allUsers
                                attachedFiles
                                customEmojis
                                stickers2
                                (index2 + 1)
                                selection
                                (List.Nonempty.toList nonempty2)
                                inBlockQuote
                                (Array.push (formatText "*") output2)
                    in
                    ( index3 + 1, Array.push (formatText "*") output3 )

                Strikethrough nonempty2 ->
                    let
                        ( index3, output3 ) =
                            textInputViewHelper
                                { state | strikethrough = True }
                                allUsers
                                attachedFiles
                                customEmojis
                                stickers2
                                (index2 + 2)
                                selection
                                (List.Nonempty.toList nonempty2)
                                inBlockQuote
                                (Array.push (formatText "~~") output2)
                    in
                    ( index3 + 2, Array.push (formatText "~~") output3 )

                Spoiler nonempty2 ->
                    let
                        ( index3, output3 ) =
                            textInputViewHelper
                                { state | spoiler = True }
                                allUsers
                                attachedFiles
                                customEmojis
                                stickers2
                                (index2 + 2)
                                selection
                                (List.Nonempty.toList nonempty2)
                                inBlockQuote
                                (Array.push (formatText "||") output2)
                    in
                    ( index3 + 2, Array.push (formatText "||") output3 )

                BlockQuote hasLeadingLineBreak nonempty2 ->
                    textInputViewHelper
                        state
                        allUsers
                        attachedFiles
                        customEmojis
                        stickers2
                        (index2 + 3)
                        selection
                        nonempty2
                        True
                        (Array.push
                            (formatText
                                (case hasLeadingLineBreak of
                                    HasLeadingLineBreak ->
                                        "\n> "

                                    NoLeadingLineBreak ->
                                        "> "
                                )
                            )
                            output2
                        )

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
                        state
                        allUsers
                        attachedFiles
                        customEmojis
                        stickers2
                        (index2 + String.length marker)
                        selection
                        (List.Nonempty.toList nonempty2)
                        inBlockQuote
                        (Array.push (formatText marker) output2)

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
                            , htmlAttrIf state.spoiler (Html.Attributes.style "background-color" "rgb(0,0,0)")
                            , Html.Attributes.style "color" "rgb(66,93,203)"
                            ]
                            [ Html.text text ]
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
                            , htmlAttrIf state.spoiler (Html.Attributes.style "background-color" "rgb(0,0,0)")
                            , Html.Attributes.style "color" "rgb(66,93,203)"
                            ]
                            [ Html.text text ]
                        )
                        output2
                    )

                InlineCode char rest ->
                    ( index2 + String.length rest + 3
                    , Array.append
                        output2
                        (Array.fromList
                            [ formatText "`"
                            , Html.span
                                [ htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                                , htmlAttrIf state.bold (Html.Attributes.style "text-shadow" "0.7px 0px 0px white")
                                , htmlAttrIf state.strikethrough (Html.Attributes.style "text-decoration" "line-through")
                                , if state.spoiler then
                                    Html.Attributes.style "background-color" "rgb(0,0,0)"

                                  else
                                    Html.Attributes.style "background-color" "rgb(90,100,120)"
                                ]
                                [ Html.text (String.cons char rest) ]
                            , formatText "`"
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
                    , Array.append output2 (Array.fromList [ formatText ("```" ++ language2), Html.text string, formatText "```" ])
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
                            formatText text

                         else
                            Html.text text
                        )
                        output2
                    )

                EscapedChar char ->
                    ( index2 + 2
                    , Array.append output2 (Array.fromList [ formatText "\\", Html.text (escapedCharToString char) ])
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
                                    , Html.Attributes.style "top" "0.1lh"
                                    , Html.Attributes.style "left" "0"
                                    ]
                                    [ CustomEmoji.view customEmojiId customEmojis Sticker.LoopForever ]
                                , Html.div
                                    [ Html.Attributes.style "position" "absolute"
                                    , Html.Attributes.style "width" CustomEmoji.emojiSize
                                    , Html.Attributes.style "height" "1lh"
                                    , Html.Attributes.style "top" "0"
                                    , Html.Attributes.style "left" "0"
                                    , if isSelected then
                                        Html.Attributes.style
                                            "background-color"
                                            (MyUi.colorToStyle (MyUi.colorWithAlpha 0.5 MyUi.selectedTextBackground))

                                      else
                                        Html.Attributes.style "opacity" "transparent"
                                    ]
                                    []
                                ]
                            , Html.span [ Html.Attributes.style "opacity" "0" ] [ Html.text text ]
                            ]
                        )
                    )
        )
        ( index, output )
        list


formatText : String -> Html msg
formatText text =
    Html.span [ Html.Attributes.style "color" "rgb(140,140,140)" ] [ Html.text text ]



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
fromDiscord text attachments2 embeds customEmojis stickers2 messageSnapshots =
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
                                customEmojis
                                []
                                |> BlockQuote NoLeadingLineBreak
                        )
                        messageSnapshots2

                Discord.Missing ->
                    []
    in
    (fromDiscordHelper text attachments2 embeds customEmojis stickers2 ++ messageSnapshots3)
        |> List.Nonempty.fromList
        |> Maybe.withDefault emptyPlaceholder


fromDiscordHelper :
    String
    -> SeqDict (Id FileId) { fileData : FileData, isSpoilered : Bool }
    -> Discord.OptionalData (List Discord.Embed)
    -> OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
    -> List (Id StickerId)
    -> List (RichText (Discord.Id Discord.UserId))
fromDiscordHelper text attachments2 embeds customEmojis stickers2 =
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
                                ( endIndex, [ BlockQuote NoLeadingLineBreak (parseDiscordBlockQuoteContent customEmojis content) ] )

                            Nothing ->
                                case extractHeading source 0 of
                                    Just ( level, content, endIndex ) ->
                                        ( endIndex, [ Heading level NoLeadingLineBreak (parseDiscordHeadingContent customEmojis content) ] )

                                    Nothing ->
                                        ( 0, [] )

                    result =
                        discordParseLoop customEmojis source startIndex [] "" startRevNodes
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
discordParseLoop customEmojis source index modifiers accText revNodes =
    if index >= String.length source then
        finalizeResult discordModifierToSymbol accText revNodes modifiers index

    else
        case String.slice index (index + 1) source of
            "\n" ->
                if List.isEmpty modifiers then
                    case extractBlockQuote source (index + 1) of
                        Just ( content, endIndex ) ->
                            discordParseLoop
                                customEmojis
                                source
                                endIndex
                                modifiers
                                ""
                                (BlockQuote HasLeadingLineBreak (parseDiscordBlockQuoteContent customEmojis content)
                                    :: flushText accText revNodes
                                )

                        Nothing ->
                            case extractHeading source (index + 1) of
                                Just ( level, content, endIndex ) ->
                                    discordParseLoop
                                        customEmojis
                                        source
                                        endIndex
                                        modifiers
                                        ""
                                        (Heading level HasLeadingLineBreak (parseDiscordHeadingContent customEmojis content)
                                            :: flushText accText revNodes
                                        )

                                Nothing ->
                                    case parseStickerId (index + 1) source of
                                        ( index2, Just stickerId ) ->
                                            discordParseLoop
                                                customEmojis
                                                source
                                                index2
                                                modifiers
                                                ""
                                                (Sticker stickerId :: flushText accText revNodes)

                                        ( _, Nothing ) ->
                                            discordParseLoop
                                                customEmojis
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
                        if Set.member nextChar discordEscapableChars then
                            discordParseLoop customEmojis source (afterBackslash + 1) modifiers (accText ++ nextChar) revNodes

                        else
                            discordParseLoop customEmojis source (afterBackslash + 1) modifiers (accText ++ "\\" ++ nextChar) revNodes

                    Nothing ->
                        discordParseLoop customEmojis source afterBackslash modifiers (accText ++ "\\") revNodes

            "<" ->
                case stringAt (index + 1) source of
                    Just "@" ->
                        case tryParseDiscordMention source index of
                            Just ( userId, nextIndex ) ->
                                discordParseLoop
                                    customEmojis
                                    source
                                    nextIndex
                                    modifiers
                                    ""
                                    (UserMention userId :: flushText accText revNodes)

                            Nothing ->
                                discordParseLoop
                                    customEmojis
                                    source
                                    (index + 1)
                                    modifiers
                                    (accText ++ "<")
                                    revNodes

                    Just "h" ->
                        case tryParseDiscordCustomEmoji customEmojis (index + 1) source of
                            Just ( emojiId, nextIndex ) ->
                                discordParseLoop
                                    customEmojis
                                    source
                                    nextIndex
                                    modifiers
                                    ""
                                    (CustomEmoji emojiId :: flushText accText revNodes)

                            Nothing ->
                                case parseUrlBody True discordModifierToSymbol modifiers (index + 1) source of
                                    Ok url ->
                                        let
                                            index2 =
                                                index + 1 + String.length (Url.toString url)
                                        in
                                        case stringAt index2 source of
                                            Just ">" ->
                                                discordParseLoop
                                                    customEmojis
                                                    source
                                                    (index2 + 1)
                                                    modifiers
                                                    ""
                                                    (Hyperlink url :: flushText accText revNodes)

                                            _ ->
                                                discordParseLoop
                                                    customEmojis
                                                    source
                                                    (index2 + 1)
                                                    modifiers
                                                    ""
                                                    (Hyperlink url :: flushText (accText ++ "<") revNodes)

                                    Err errText ->
                                        discordParseLoop
                                            customEmojis
                                            source
                                            (index + 1 + String.length errText)
                                            modifiers
                                            (accText ++ "<" ++ errText)
                                            revNodes

                    Just ":" ->
                        case tryParseDiscordCustomEmoji customEmojis (index + 2) source of
                            Just ( emojiId, nextIndex ) ->
                                discordParseLoop
                                    customEmojis
                                    source
                                    nextIndex
                                    modifiers
                                    ""
                                    (CustomEmoji emojiId :: flushText accText revNodes)

                            Nothing ->
                                discordParseLoop customEmojis source (index + 1) modifiers (accText ++ "<") revNodes

                    _ ->
                        discordParseLoop customEmojis source (index + 1) modifiers (accText ++ "<") revNodes

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
                                discordParseInner customEmojis source afterSymbol (DiscordIsBold :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        discordParseLoop customEmojis source inner.nextIndex modifiers "" newRevNodes

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
                            discordParseLoop customEmojis source afterSymbol modifiers (accText ++ "*") revNodes

                        else
                            let
                                flushed =
                                    flushText accText revNodes

                                inner =
                                    discordParseInner customEmojis source afterSymbol (DiscordIsItalic :: modifiers)

                                newRevNodes =
                                    List.foldl (\node acc -> node :: acc) flushed inner.nodes
                            in
                            discordParseLoop customEmojis source inner.nextIndex modifiers "" newRevNodes

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
                                discordParseInner customEmojis source afterSymbol (DiscordIsUnderlined :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        discordParseLoop customEmojis source inner.nextIndex modifiers "" newRevNodes

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
                                discordParseInner customEmojis source afterSymbol (DiscordIsItalic2 :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        discordParseLoop customEmojis source inner.nextIndex modifiers "" newRevNodes

            "~" ->
                if (List.head modifiers /= Just DiscordIsStrikethrough) && String.slice index (index + 4) source == "~~~~" then
                    discordParseLoop customEmojis source (index + 4) modifiers (accText ++ "~~~~") revNodes

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
                                discordParseInner customEmojis source afterSymbol (DiscordIsStrikethrough :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        discordParseLoop customEmojis source inner.nextIndex modifiers "" newRevNodes

                else
                    discordParseLoop customEmojis source (index + 1) modifiers (accText ++ "~") revNodes

            "|" ->
                if (List.head modifiers /= Just DiscordIsSpoilered) && String.slice index (index + 4) source == "||||" then
                    discordParseLoop customEmojis source (index + 4) modifiers (accText ++ "||||") revNodes

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
                                discordParseInner customEmojis source afterSymbol (DiscordIsSpoilered :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        discordParseLoop customEmojis source inner.nextIndex modifiers "" newRevNodes

                else
                    discordParseLoop customEmojis source (index + 1) modifiers (accText ++ "|") revNodes

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
                                    customEmojis
                                    source
                                    (closeIndex + 3)
                                    modifiers
                                    ""
                                    (CodeBlock language codeContent :: flushText accText revNodes)

                            Nothing ->
                                discordParseLoop
                                    customEmojis
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
                                            customEmojis
                                            source
                                            (closeIndex + 1)
                                            modifiers
                                            ""
                                            (InlineCode (String.Nonempty.head a) (String.Nonempty.tail a) :: flushText accText revNodes)

                                    _ ->
                                        discordParseLoop customEmojis source (index + 1) modifiers (accText ++ "`") revNodes

                            Nothing ->
                                discordParseLoop customEmojis source (index + 1) modifiers (accText ++ "`") revNodes

            "h" ->
                case parseUrlBody False discordModifierToSymbol modifiers index source of
                    Ok url ->
                        discordParseLoop
                            customEmojis
                            source
                            (index + String.length (Url.toString url))
                            modifiers
                            ""
                            (Hyperlink url :: flushText accText revNodes)

                    Err errText ->
                        discordParseLoop
                            customEmojis
                            source
                            (index + String.length errText)
                            modifiers
                            (accText ++ errText)
                            revNodes

            "[" ->
                case parseMarkdownLink source (index + 1) of
                    Just ( alias, url, nextIndex ) ->
                        discordParseLoop
                            customEmojis
                            source
                            nextIndex
                            modifiers
                            ""
                            (MarkdownLink alias url :: flushText accText revNodes)

                    Nothing ->
                        discordParseLoop customEmojis source (index + 1) modifiers (accText ++ "[") revNodes

            _ ->
                let
                    nextIndex =
                        skipDiscordNormalChars source (index + 1) (String.length source)
                in
                discordParseLoop
                    customEmojis
                    source
                    nextIndex
                    modifiers
                    (accText ++ String.slice index nextIndex source)
                    revNodes


toDiscord :
    OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
    -> Nonempty (RichText (Discord.Id Discord.UserId))
    -> Result Int String
toDiscord customEmojis content =
    let
        text =
            toDiscordHelper customEmojis (List.Nonempty.toList content)
    in
    if String.length text > maxLength then
        Err (maxLength - String.length text)

    else
        Ok text


discordCharsLeft :
    OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
    -> Maybe (Nonempty (RichText (Discord.Id Discord.UserId)))
    -> Int
discordCharsLeft customEmojis richText =
    case richText of
        Just richText2 ->
            case toDiscord customEmojis richText2 of
                Ok text ->
                    maxLength - String.length text

                Err charsLeft ->
                    charsLeft

        Nothing ->
            maxLength


type alias DiscordCustomEmojiIdAndName =
    { id : Discord.Id Discord.CustomEmojiId, name : EmojiName }


toDiscordHelper :
    OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
    -> List (RichText (Discord.Id Discord.UserId))
    -> String
toDiscordHelper customEmojis content =
    List.map
        (\item ->
            case item of
                UserMention discordUserId ->
                    "<@!" ++ Discord.idToString discordUserId ++ ">"

                NormalText char string ->
                    escapeDiscordText (String.cons char string)

                Bold nonempty ->
                    "**" ++ toDiscordHelper customEmojis (List.Nonempty.toList nonempty) ++ "**"

                Italic nonempty ->
                    "*" ++ toDiscordHelper customEmojis (List.Nonempty.toList nonempty) ++ "*"

                Underline nonempty ->
                    "__" ++ toDiscordHelper customEmojis (List.Nonempty.toList nonempty) ++ "__"

                Strikethrough nonempty ->
                    "~~" ++ toDiscordHelper customEmojis (List.Nonempty.toList nonempty) ++ "~~"

                Spoiler nonempty ->
                    "||" ++ toDiscordHelper customEmojis (List.Nonempty.toList nonempty) ++ "||"

                BlockQuote _ list ->
                    "\n> " ++ String.replace "\n" "\n> " (toDiscordHelper customEmojis list)

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
                    prefix ++ toDiscordHelper customEmojis (List.Nonempty.toList nonempty)

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
                    case OneToOne.first id customEmojis of
                        Just discordIdAndName ->
                            "<:"
                                ++ CustomEmoji.emojiNameToString discordIdAndName.name
                                ++ ":"
                                ++ Discord.idToString discordIdAndName.id
                                ++ ">"

                        Nothing ->
                            "<missing:123123123>"
        )
        content
        |> String.concat


customEmojisFromDiscord : String -> List ( String, Discord.Id Discord.CustomEmojiId )
customEmojisFromDiscord text =
    String.split "<" text
        |> List.filterMap
            (\text2 ->
                case String.split ">" text2 of
                    head :: _ ->
                        case String.split ":" head of
                            [ name, id ] ->
                                case Discord.idFromString id of
                                    Just id2 ->
                                        Just ( name, id2 )

                                    Nothing ->
                                        Nothing

                            _ ->
                                Nothing

                    [] ->
                        Nothing
            )


escapeDiscordText : String -> String
escapeDiscordText text =
    String.replace "\\" "\\\\" text
        |> String.replace "_" "\\_"
        |> String.replace "*" "\\*"
        |> String.replace "`" "\\`"
        |> String.replace ">" "\\>"
        |> String.replace "@" "\\@"
        |> String.replace "~" "\\~"


discordParseInner :
    OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
    -> String
    -> Int
    -> List DiscordModifiers
    -> { nodes : List (RichText (Discord.Id Discord.UserId)), nextIndex : Int }
discordParseInner customEmojis source index modifiers =
    discordParseLoop customEmojis source index modifiers "" []


parseDiscordBlockQuoteContent : OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId) -> String -> List (RichText (Discord.Id Discord.UserId))
parseDiscordBlockQuoteContent customEmojis content =
    case discordParseLoop customEmojis content 0 [] "" [] |> .nodes |> List.Nonempty.fromList of
        Just nonempty ->
            normalize nonempty |> List.Nonempty.toList

        Nothing ->
            []


parseDiscordHeadingContent : OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId) -> NonemptyString -> Nonempty (RichText (Discord.Id Discord.UserId))
parseDiscordHeadingContent customEmojis content =
    case discordParseLoop customEmojis (String.Nonempty.toString content) 0 [] "" [] |> .nodes |> List.Nonempty.fromList of
        Just nonempty ->
            normalize nonempty

        Nothing ->
            Nonempty (NormalText (String.Nonempty.head content) (String.Nonempty.tail content)) []


tryParseDiscordCustomEmoji :
    OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
    -> Int
    -> String
    -> Maybe ( Id CustomEmojiId, Int )
tryParseDiscordCustomEmoji customEmojis index source =
    case ( findChar source index (String.length source) ':', findChar source index (String.length source) '>' ) of
        ( Just nameEnd, Just idEnd ) ->
            if nameEnd < idEnd then
                case
                    ( String.slice index nameEnd source |> CustomEmoji.emojiNameFromString
                    , String.slice (nameEnd + 1) idEnd source |> Discord.idFromString
                    )
                of
                    ( Ok name, Just discordId ) ->
                        case OneToOne.second { id = discordId, name = name } customEmojis of
                            Just emojiId ->
                                Just ( emojiId, idEnd + 1 )

                            Nothing ->
                                Nothing

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
