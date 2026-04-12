module RichText exposing
    ( Domain(..)
    , EscapedChar(..)
    , Language(..)
    , Modifiers(..)
    , RichText(..)
    , RichTextState
    , attachedFilePrefix
    , attachedFileSuffix
    , attachments
    , domainToString
    , emptyPlaceholder
    , escapedCharToString
    , fromDiscord
    , fromNonemptyString
    , hyperlinks
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
import Dict exposing (Dict)
import Discord
import Discord.Markdown
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Time as Time
import Embed exposing (Embed(..), EmbedData)
import FileName
import FileStatus exposing (FileData, FileId)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Icons
import Id exposing (Id, StickerId)
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import MyUi
import NonemptyExtra
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
    | Hyperlink Url
    | MarkdownLink NonemptyString Url
    | InlineCode Char String
    | CodeBlock Language String
    | AttachedFile (Id FileId)
    | EscapedChar EscapedChar
    | Sticker (Id StickerId)


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
        )
        (List.Nonempty.toList nonempty)


toStringWithGetter : (a -> String) -> SeqDict userId a -> Nonempty (RichText userId) -> String
toStringWithGetter userToString users nonempty =
    List.Nonempty.map
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
                    "*" ++ toStringWithGetter userToString users a ++ "*"

                Italic a ->
                    "_" ++ toStringWithGetter userToString users a ++ "_"

                Underline a ->
                    "__" ++ toStringWithGetter userToString users a ++ "__"

                Strikethrough a ->
                    "~~" ++ toStringWithGetter userToString users a ++ "~~"

                Spoiler a ->
                    "||" ++ toStringWithGetter userToString users a ++ "||"

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
                    attachedFilePrefix ++ Id.toString fileId ++ attachedFileSuffix

                EscapedChar char ->
                    "\\" ++ escapedCharToString char

                Sticker id ->
                    Sticker.idToString id
        )
        nonempty
        |> List.Nonempty.toList
        |> String.concat


toString : Bool -> SeqDict userId { a | name : PersonName } -> Nonempty (RichText userId) -> String
toString emojisForStickersAndAttachments users nonempty =
    List.Nonempty.map
        (\richText ->
            case richText of
                NormalText char rest ->
                    String.cons char rest

                UserMention userId ->
                    case SeqDict.get userId users of
                        Just user ->
                            "@" ++ PersonName.toString user.name

                        Nothing ->
                            "@<missing>"

                Bold a ->
                    "*" ++ toString emojisForStickersAndAttachments users a ++ "*"

                Italic a ->
                    "_" ++ toString emojisForStickersAndAttachments users a ++ "_"

                Underline a ->
                    "__" ++ toString emojisForStickersAndAttachments users a ++ "__"

                Strikethrough a ->
                    "~~" ++ toString emojisForStickersAndAttachments users a ++ "~~"

                Spoiler a ->
                    "||" ++ toString emojisForStickersAndAttachments users a ++ "||"

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
        )
        nonempty
        |> List.Nonempty.toList
        |> String.concat


fromNonemptyString : SeqDict userId { a | name : PersonName } -> NonemptyString -> Nonempty (RichText userId)
fromNonemptyString users string =
    let
        source =
            String.Nonempty.toString string

        len =
            String.length source

        result =
            parseLoop source 0 len users [] "" []
    in
    case List.Nonempty.fromList result.nodes of
        Just nonempty ->
            normalize nonempty

        Nothing ->
            Nonempty (normalTextFromNonempty string) []


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


finalizeResult : String -> List (RichText userId) -> List Modifiers -> Int -> { nodes : List (RichText userId), nextIndex : Int }
finalizeResult accText revNodes modifiers index =
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
                        modifierToSymbol head
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


parseInner : String -> Int -> Int -> SeqDict userId { a | name : PersonName } -> List Modifiers -> { nodes : List (RichText userId), nextIndex : Int }
parseInner source index len users modifiers =
    parseLoop source index len users modifiers "" []


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
    -> Int
    -> SeqDict userId { a | name : PersonName }
    -> List Modifiers
    -> String
    -> List (RichText userId)
    -> { nodes : List (RichText userId), nextIndex : Int }
parseLoop source index sourceLength users modifiers accText revNodes =
    if index >= sourceLength then
        finalizeResult accText revNodes modifiers index

    else
        case String.slice index (index + 1) source of
            "\n" ->
                case parseStickerId (index + 1) source of
                    ( index2, Just stickerId ) ->
                        parseLoop source index2 sourceLength users modifiers "" (Sticker stickerId :: flushText accText revNodes)

                    ( _, Nothing ) ->
                        parseLoop source (index + 1) sourceLength users modifiers (accText ++ "\n") revNodes

            "\\" ->
                let
                    afterBackslash =
                        index + 1
                in
                case stringAt afterBackslash source of
                    Just nextChar ->
                        case Dict.get nextChar charToEscaped of
                            Just escaped ->
                                parseLoop source (afterBackslash + 1) sourceLength users modifiers "" (EscapedChar escaped :: flushText accText revNodes)

                            Nothing ->
                                parseLoop source (afterBackslash + 1) sourceLength users modifiers (accText ++ "\\" ++ nextChar) revNodes

                    Nothing ->
                        parseLoop source afterBackslash sourceLength users modifiers (accText ++ "\\") revNodes

            "@" ->
                let
                    afterAt =
                        index + 1

                    remaining =
                        String.slice afterAt sourceLength source
                in
                case tryMatchUser users remaining of
                    Just ( userId, matchLen ) ->
                        parseLoop source (afterAt + matchLen) sourceLength users modifiers "" (UserMention userId :: flushText accText revNodes)

                    Nothing ->
                        parseLoop source afterAt sourceLength users modifiers (accText ++ "@") revNodes

            "*" ->
                let
                    afterSymbol =
                        index + 1
                in
                if List.head modifiers == Just IsBold then
                    closeModifier afterSymbol accText revNodes Bold (modifierToSymbol IsBold)

                else if List.member IsBold modifiers then
                    finalizeResult accText revNodes modifiers index

                else
                    let
                        nextChar =
                            String.slice afterSymbol (afterSymbol + 1) source
                    in
                    if nextChar == "*" || nextChar == " " then
                        parseLoop source afterSymbol sourceLength users modifiers (accText ++ "*") revNodes

                    else
                        let
                            flushed =
                                flushText accText revNodes

                            inner =
                                parseInner source afterSymbol sourceLength users (IsBold :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        parseLoop source inner.nextIndex sourceLength users modifiers "" newRevNodes

            "_" ->
                if String.slice index (index + 4) source == "____" then
                    parseLoop source (index + 4) sourceLength users modifiers (accText ++ "____") revNodes

                else if String.slice index (index + 2) source == "__" then
                    let
                        afterSymbol =
                            index + 2
                    in
                    if List.head modifiers == Just IsUnderlined then
                        closeModifier afterSymbol accText revNodes Underline (modifierToSymbol IsUnderlined)

                    else if List.member IsUnderlined modifiers then
                        finalizeResult accText revNodes modifiers index

                    else
                        let
                            flushed =
                                flushText accText revNodes

                            inner =
                                parseInner source afterSymbol sourceLength users (IsUnderlined :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        parseLoop source inner.nextIndex sourceLength users modifiers "" newRevNodes

                else
                    let
                        afterSymbol =
                            index + 1
                    in
                    if List.head modifiers == Just IsItalic then
                        closeModifier afterSymbol accText revNodes Italic (modifierToSymbol IsItalic)

                    else if List.member IsItalic modifiers then
                        finalizeResult accText revNodes modifiers index

                    else
                        let
                            flushed =
                                flushText accText revNodes

                            inner =
                                parseInner source afterSymbol sourceLength users (IsItalic :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        parseLoop source inner.nextIndex sourceLength users modifiers "" newRevNodes

            "~" ->
                if (List.head modifiers /= Just IsStrikethrough) && String.slice index (index + 4) source == "~~~~" then
                    parseLoop source (index + 4) sourceLength users modifiers (accText ++ "~~~~") revNodes

                else if String.slice index (index + 2) source == "~~" then
                    let
                        afterSymbol =
                            index + 2
                    in
                    if List.head modifiers == Just IsStrikethrough then
                        closeModifier afterSymbol accText revNodes Strikethrough (modifierToSymbol IsStrikethrough)

                    else if List.member IsStrikethrough modifiers then
                        finalizeResult accText revNodes modifiers index

                    else
                        let
                            flushed =
                                flushText accText revNodes

                            inner =
                                parseInner source afterSymbol sourceLength users (IsStrikethrough :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        parseLoop source inner.nextIndex sourceLength users modifiers "" newRevNodes

                else
                    parseLoop source (index + 1) sourceLength users modifiers (accText ++ "~") revNodes

            "|" ->
                if (List.head modifiers /= Just IsSpoilered) && String.slice index (index + 4) source == "||||" then
                    parseLoop source (index + 4) sourceLength users modifiers (accText ++ "||||") revNodes

                else if String.slice index (index + 2) source == "||" then
                    let
                        afterSymbol =
                            index + 2
                    in
                    if List.head modifiers == Just IsSpoilered then
                        closeModifier afterSymbol accText revNodes Spoiler (modifierToSymbol IsSpoilered)

                    else if List.member IsSpoilered modifiers then
                        finalizeResult accText revNodes modifiers index

                    else
                        let
                            flushed =
                                flushText accText revNodes

                            inner =
                                parseInner source afterSymbol sourceLength users (IsSpoilered :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        parseLoop source inner.nextIndex sourceLength users modifiers "" newRevNodes

                else
                    parseLoop source (index + 1) sourceLength users modifiers (accText ++ "|") revNodes

            "`" ->
                if String.slice index (index + 3) source == "```" then
                    case findSubstring source (index + 3) sourceLength "```" of
                        Just closeIndex ->
                            let
                                content =
                                    String.slice (index + 3) closeIndex source

                                ( language, codeContent ) =
                                    parseCodeBlockContent content
                            in
                            case String.Nonempty.fromString codeContent of
                                Just _ ->
                                    parseLoop source (closeIndex + 3) sourceLength users modifiers "" (CodeBlock language codeContent :: flushText accText revNodes)

                                Nothing ->
                                    parseLoop source (closeIndex + 3) sourceLength users modifiers (accText ++ "``````") revNodes

                        Nothing ->
                            -- No closing ```, try inline code
                            case findSingleBacktick source (index + 1) sourceLength of
                                Just closeIndex ->
                                    let
                                        content =
                                            String.slice (index + 1) closeIndex source
                                    in
                                    case String.Nonempty.fromString content of
                                        Just a ->
                                            parseLoop source (closeIndex + 1) sourceLength users modifiers "" (InlineCode (String.Nonempty.head a) (String.Nonempty.tail a) :: flushText accText revNodes)

                                        Nothing ->
                                            parseLoop source (closeIndex + 1) sourceLength users modifiers (accText ++ "``") revNodes

                                Nothing ->
                                    parseLoop source (index + 1) sourceLength users modifiers (accText ++ "`") revNodes

                else
                    case findSingleBacktick source (index + 1) sourceLength of
                        Just closeIndex ->
                            let
                                content =
                                    String.slice (index + 1) closeIndex source
                            in
                            case String.Nonempty.fromString content of
                                Just a ->
                                    parseLoop source (closeIndex + 1) sourceLength users modifiers "" (InlineCode (String.Nonempty.head a) (String.Nonempty.tail a) :: flushText accText revNodes)

                                Nothing ->
                                    parseLoop source (closeIndex + 1) sourceLength users modifiers (accText ++ "``") revNodes

                        Nothing ->
                            parseLoop source (index + 1) sourceLength users modifiers (accText ++ "`") revNodes

            "h" ->
                case parseUrlBody False modifierToSymbol modifiers index source of
                    Ok url ->
                        parseLoop
                            source
                            (index + String.length (Url.toString url))
                            sourceLength
                            users
                            modifiers
                            ""
                            (Hyperlink url :: flushText accText revNodes)

                    Err errText ->
                        parseLoop
                            source
                            (index + String.length errText)
                            sourceLength
                            users
                            modifiers
                            (accText ++ errText)
                            revNodes

            "[" ->
                if String.slice index (index + 2) source == "[!" then
                    case parseFileId source (index + 2) sourceLength of
                        Just ( fileId, nextIndex ) ->
                            parseLoop source nextIndex sourceLength users modifiers "" (AttachedFile (Id.fromInt fileId) :: flushText accText revNodes)

                        Nothing ->
                            parseLoop source (index + 1) sourceLength users modifiers (accText ++ "[") revNodes

                else
                    case parseMarkdownLink source (index + 1) sourceLength of
                        Just ( alias, url, nextIndex ) ->
                            parseLoop source nextIndex sourceLength users modifiers "" (MarkdownLink alias url :: flushText accText revNodes)

                        Nothing ->
                            parseLoop source (index + 1) sourceLength users modifiers (accText ++ "[") revNodes

            _ ->
                let
                    nextIndex =
                        skipNormalChars source (index + 1) sourceLength
                in
                parseLoop source nextIndex sourceLength users modifiers (accText ++ String.slice index nextIndex source) revNodes


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


findSubstring : String -> Int -> Int -> String -> Maybe Int
findSubstring source index len target =
    let
        targetLen =
            String.length target
    in
    if index + targetLen > len then
        Nothing

    else if String.slice index (index + targetLen) source == target then
        Just index

    else
        findSubstring source (index + 1) len target


findSingleBacktick : String -> Int -> Int -> Maybe Int
findSingleBacktick source index len =
    if index >= len then
        Nothing

    else if String.slice index (index + 1) source == "`" then
        Just index

    else
        findSingleBacktick source (index + 1) len


parseMarkdownLink : String -> Int -> Int -> Maybe ( NonemptyString, Url, Int )
parseMarkdownLink source index len =
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


parseFileId : String -> Int -> Int -> Maybe ( Int, Int )
parseFileId source index len =
    let
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


skipNormalChars : String -> Int -> Int -> Int
skipNormalChars source index len =
    if index >= len then
        index

    else
        let
            c =
                String.slice index (index + 1) source
        in
        if c == "[" || c == "@" || c == "h" || c == "`" || c == "\\" || c == "*" || c == "_" || c == "~" || c == "|" || c == "\n" then
            index

        else
            skipNormalChars source (index + 1) len


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
    , animationMode : Sticker.AnimationMode
    }


type alias PreviewConfig a userId =
    { domainWhitelist : SeqSet Domain
    , revealedSpoilers : SeqSet Int
    , users : SeqDict userId { a | name : PersonName }
    , attachedFiles : SeqDict (Id FileId) FileData
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
    ShowLargeContent
    -> Maybe ( HtmlId, Int -> msg )
    -> (Url -> msg)
    -> Int
    -> RichTextState
    -> Config a userId
    -> Array Embed
    -> Int
    -> Nonempty (RichText userId)
    -> ( Int, Int, List (Html msg) )
viewHelper showLargeContent maybePressedSpoiler onPressLink spoilerIndex state config embeds embedIndex nonempty =
    List.foldl
        (\item ( spoilerIndex2, embedIndex2, currentList ) ->
            case item of
                UserMention userId ->
                    ( spoilerIndex2, embedIndex2, currentList ++ [ MyUi.userLabelHtml userId config.users ] )

                NormalText char text ->
                    ( spoilerIndex2
                    , embedIndex2
                    , currentList ++ normalTextView (String.cons char text) state
                    )

                Italic nonempty2 ->
                    let
                        ( spoilerIndex3, embedIndex3, list ) =
                            viewHelper
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
                    ( spoilerIndex3, embedIndex3, currentList ++ list )

                Underline nonempty2 ->
                    let
                        ( spoilerIndex3, embedIndex3, list ) =
                            viewHelper
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
                    ( spoilerIndex3, embedIndex3, currentList ++ list )

                Bold nonempty2 ->
                    let
                        ( spoilerIndex3, embedIndex3, list ) =
                            viewHelper
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
                    ( spoilerIndex3, embedIndex3, currentList ++ list )

                Strikethrough nonempty2 ->
                    let
                        ( spoilerIndex3, embedIndex3, list ) =
                            viewHelper
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
                    ( spoilerIndex3, embedIndex3, currentList ++ list )

                Spoiler nonempty2 ->
                    let
                        revealed =
                            SeqSet.member spoilerIndex2 config.revealedSpoilers

                        -- Ignore the spoiler index value. It shouldn't be possible to have nested spoilers
                        ( _, embedIndex3, list ) =
                            viewHelper
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
                    ( spoilerIndex2 + 1
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

                Hyperlink data ->
                    let
                        text : String
                        text =
                            Url.toString data
                    in
                    ( spoilerIndex2
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
                    ( spoilerIndex2
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
                    ( spoilerIndex2
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
                            ( spoilerIndex2
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
                            ( spoilerIndex2, embedIndex2, currentList ++ [ Html.text "<...>" ] )

                AttachedFile fileId ->
                    case showLargeContent of
                        ShowLargeContent containerWidth2 ->
                            ( spoilerIndex2
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
                            ( spoilerIndex2, embedIndex2, currentList ++ [ Icons.image ] )

                EscapedChar char ->
                    ( spoilerIndex2, embedIndex2, currentList ++ [ Html.text (escapedCharToString char) ] )

                Sticker stickerId ->
                    case showLargeContent of
                        ShowLargeContent _ ->
                            ( spoilerIndex2
                            , embedIndex2
                            , currentList ++ [ Sticker.view "160px" stickerId config.stickers config.animationMode ]
                            )

                        NoLargeContent ->
                            ( spoilerIndex2, embedIndex2, currentList ++ [ Icons.image ] )
        )
        ( spoilerIndex, embedIndex, [] )
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
    -> SeqDict (Id StickerId) StickerData
    -> Maybe Range
    -> Nonempty (RichText userId)
    -> List (Html msg)
textInputView users attachedFiles stickers2 selection nonempty =
    textInputViewHelper
        { underline = False, italic = False, bold = False, strikethrough = False, spoiler = False }
        users
        attachedFiles
        stickers2
        0
        selection
        nonempty
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
    -> SeqDict (Id StickerId) StickerData
    -> Int
    -> Maybe Range
    -> Nonempty (RichText userId)
    -> Array (Html msg)
    -> ( Int, Array (Html msg) )
textInputViewHelper state allUsers attachedFiles stickers2 index selection nonempty output =
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
                    ( index2 + String.length text + 1
                    , Array.push
                        (Html.span
                            [ htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                            , htmlAttrIf state.bold (Html.Attributes.style "text-shadow" "0.7px 0px 0px white")
                            , htmlAttrIf state.strikethrough (Html.Attributes.style "text-decoration" "line-through")
                            , htmlAttrIf state.spoiler (Html.Attributes.style "background-color" "rgb(0,0,0)")
                            ]
                            [ Html.text (String.cons char text) ]
                        )
                        output2
                    )

                Italic nonempty2 ->
                    let
                        ( index3, output3 ) =
                            textInputViewHelper
                                { state | italic = True }
                                allUsers
                                attachedFiles
                                stickers2
                                (index2 + 1)
                                selection
                                nonempty2
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
                                stickers2
                                (index2 + 2)
                                selection
                                nonempty2
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
                                stickers2
                                (index2 + 1)
                                selection
                                nonempty2
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
                                stickers2
                                (index2 + 2)
                                selection
                                nonempty2
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
                                stickers2
                                (index2 + 2)
                                selection
                                nonempty2
                                (Array.push (formatText "||") output2)
                    in
                    ( index3 + 2, Array.push (formatText "||") output3 )

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
                            [ Html.span
                                [ Html.Attributes.style "position" "relative" ]
                                [ Html.div
                                    [ Html.Attributes.style "position" "absolute"
                                    , if isSelected then
                                        Html.Attributes.style "background-color" (MyUi.colorToStyle MyUi.selectedTextBackground)

                                      else
                                        Html.Attributes.style "opacity" "transparent"
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
                                    ]
                                    []
                                ]
                            , Html.text "\n\n\n"
                            ]
                        )
                    )
        )
        ( index, output )
        (List.Nonempty.toList nonempty)


formatText : String -> Html msg
formatText text =
    Html.span [ Html.Attributes.style "color" "rgb(180,180,180)" ] [ Html.text text ]



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
    -> List (Id StickerId)
    -> Nonempty (RichText (Discord.Id Discord.UserId))
fromDiscord text attachments2 embeds stickers2 =
    let
        embedSet : SeqSet Url
        embedSet =
            List.filterMap
                (\embed ->
                    case embed.url of
                        Discord.Included url ->
                            Url.fromString url

                        Discord.Missing ->
                            Nothing
                )
                (case embeds of
                    Discord.Included embeds2 ->
                        embeds2

                    Discord.Missing ->
                        []
                )
                |> SeqSet.fromList

        applyExtraEmbeds : Nonempty (RichText userId) -> Nonempty (RichText userId)
        applyExtraEmbeds richText =
            let
                urls : List Url
                urls =
                    hyperlinks richText
            in
            --This is to detect if we actually have embeds that are not attached to any url or if we just have embeds with canonicalized urls that don't match up with the urls in the message
            if SeqSet.size embedSet > List.length urls then
                case
                    List.foldl SeqSet.remove embedSet urls
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

        applyStickers : List (RichText userId) -> Nonempty (RichText userId)
        applyStickers richText =
            case richText ++ List.map Sticker stickers2 |> List.Nonempty.fromList of
                Just nonempty ->
                    nonempty

                Nothing ->
                    emptyPlaceholder

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
    in
    case String.Nonempty.fromString text of
        Just nonempty ->
            NonemptyExtra.appendList
                (let
                    result =
                        discordParseLoop text 0 (String.length text) [] "" []
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
                    SeqSet.toList embedSet
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
    String
    -> Int
    -> Int
    -> List DiscordModifiers
    -> String
    -> List (RichText (Discord.Id Discord.UserId))
    -> { nodes : List (RichText (Discord.Id Discord.UserId)), nextIndex : Int }
discordParseLoop source index sourceLength modifiers accText revNodes =
    if index >= sourceLength then
        discordFinalizeResult accText revNodes modifiers index

    else
        case String.slice index (index + 1) source of
            "\\" ->
                let
                    afterBackslash =
                        index + 1
                in
                case stringAt afterBackslash source of
                    Just nextChar ->
                        if Set.member nextChar discordEscapableChars then
                            discordParseLoop source (afterBackslash + 1) sourceLength modifiers (accText ++ nextChar) revNodes

                        else
                            discordParseLoop source (afterBackslash + 1) sourceLength modifiers (accText ++ "\\" ++ nextChar) revNodes

                    Nothing ->
                        discordParseLoop source afterBackslash sourceLength modifiers (accText ++ "\\") revNodes

            "<" ->
                case tryParseDiscordMention source index sourceLength of
                    Just ( userId, nextIndex ) ->
                        discordParseLoop source nextIndex sourceLength modifiers "" (UserMention userId :: flushText accText revNodes)

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
                                            source
                                            (index2 + 1)
                                            sourceLength
                                            modifiers
                                            ""
                                            (Hyperlink url :: flushText accText revNodes)

                                    _ ->
                                        discordParseLoop
                                            source
                                            (index2 + 1)
                                            sourceLength
                                            modifiers
                                            ""
                                            (Hyperlink url :: flushText (accText ++ "<") revNodes)

                            Err errText ->
                                discordParseLoop
                                    source
                                    (index + 1 + String.length errText)
                                    sourceLength
                                    modifiers
                                    (accText ++ "<" ++ errText)
                                    revNodes

            "*" ->
                if String.slice index (index + 2) source == "**" then
                    let
                        afterSymbol =
                            index + 2
                    in
                    if List.head modifiers == Just DiscordIsBold then
                        closeModifier afterSymbol accText revNodes Bold (discordModifierToSymbol DiscordIsBold)

                    else if List.member DiscordIsBold modifiers then
                        discordFinalizeResult accText revNodes modifiers index

                    else
                        let
                            flushed =
                                flushText accText revNodes

                            inner =
                                discordParseInner source afterSymbol sourceLength (DiscordIsBold :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        discordParseLoop source inner.nextIndex sourceLength modifiers "" newRevNodes

                else
                    let
                        afterSymbol =
                            index + 1
                    in
                    if List.head modifiers == Just DiscordIsItalic then
                        closeModifier afterSymbol accText revNodes Italic (discordModifierToSymbol DiscordIsItalic)

                    else if List.member DiscordIsItalic modifiers then
                        discordFinalizeResult accText revNodes modifiers index

                    else
                        let
                            nextChar =
                                String.slice afterSymbol (afterSymbol + 1) source
                        in
                        if nextChar == "*" || nextChar == " " then
                            discordParseLoop source afterSymbol sourceLength modifiers (accText ++ "*") revNodes

                        else
                            let
                                flushed =
                                    flushText accText revNodes

                                inner =
                                    discordParseInner source afterSymbol sourceLength (DiscordIsItalic :: modifiers)

                                newRevNodes =
                                    List.foldl (\node acc -> node :: acc) flushed inner.nodes
                            in
                            discordParseLoop source inner.nextIndex sourceLength modifiers "" newRevNodes

            "_" ->
                if String.slice index (index + 2) source == "__" then
                    let
                        afterSymbol =
                            index + 2
                    in
                    if List.head modifiers == Just DiscordIsUnderlined then
                        closeModifier afterSymbol accText revNodes Underline (discordModifierToSymbol DiscordIsUnderlined)

                    else if List.member DiscordIsUnderlined modifiers then
                        discordFinalizeResult accText revNodes modifiers index

                    else
                        let
                            flushed =
                                flushText accText revNodes

                            inner =
                                discordParseInner source afterSymbol sourceLength (DiscordIsUnderlined :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        discordParseLoop source inner.nextIndex sourceLength modifiers "" newRevNodes

                else
                    let
                        afterSymbol =
                            index + 1
                    in
                    if List.head modifiers == Just DiscordIsItalic2 then
                        closeModifier afterSymbol accText revNodes Italic (discordModifierToSymbol DiscordIsItalic2)

                    else if List.member DiscordIsItalic2 modifiers then
                        discordFinalizeResult accText revNodes modifiers index

                    else
                        let
                            flushed =
                                flushText accText revNodes

                            inner =
                                discordParseInner source afterSymbol sourceLength (DiscordIsItalic2 :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        discordParseLoop source inner.nextIndex sourceLength modifiers "" newRevNodes

            "~" ->
                if (List.head modifiers /= Just DiscordIsStrikethrough) && String.slice index (index + 4) source == "~~~~" then
                    discordParseLoop source (index + 4) sourceLength modifiers (accText ++ "~~~~") revNodes

                else if String.slice index (index + 2) source == "~~" then
                    let
                        afterSymbol =
                            index + 2
                    in
                    if List.head modifiers == Just DiscordIsStrikethrough then
                        closeModifier afterSymbol accText revNodes Strikethrough (discordModifierToSymbol DiscordIsStrikethrough)

                    else if List.member DiscordIsStrikethrough modifiers then
                        discordFinalizeResult accText revNodes modifiers index

                    else
                        let
                            flushed =
                                flushText accText revNodes

                            inner =
                                discordParseInner source afterSymbol sourceLength (DiscordIsStrikethrough :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        discordParseLoop source inner.nextIndex sourceLength modifiers "" newRevNodes

                else
                    discordParseLoop source (index + 1) sourceLength modifiers (accText ++ "~") revNodes

            "|" ->
                if (List.head modifiers /= Just DiscordIsSpoilered) && String.slice index (index + 4) source == "||||" then
                    discordParseLoop source (index + 4) sourceLength modifiers (accText ++ "||||") revNodes

                else if String.slice index (index + 2) source == "||" then
                    let
                        afterSymbol =
                            index + 2
                    in
                    if List.head modifiers == Just DiscordIsSpoilered then
                        closeModifier afterSymbol accText revNodes Spoiler (discordModifierToSymbol DiscordIsSpoilered)

                    else if List.member DiscordIsSpoilered modifiers then
                        discordFinalizeResult accText revNodes modifiers index

                    else
                        let
                            flushed =
                                flushText accText revNodes

                            inner =
                                discordParseInner source afterSymbol sourceLength (DiscordIsSpoilered :: modifiers)

                            newRevNodes =
                                List.foldl (\node acc -> node :: acc) flushed inner.nodes
                        in
                        discordParseLoop source inner.nextIndex sourceLength modifiers "" newRevNodes

                else
                    discordParseLoop source (index + 1) sourceLength modifiers (accText ++ "|") revNodes

            "`" ->
                if String.slice index (index + 3) source == "```" then
                    case findSubstring source (index + 3) sourceLength "```" of
                        Just closeIndex ->
                            let
                                content =
                                    String.slice (index + 3) closeIndex source

                                ( language, codeContent ) =
                                    case String.split "\n" content of
                                        [ single ] ->
                                            ( NoLanguage, single )

                                        head :: rest ->
                                            if String.contains " " head then
                                                ( NoLanguage, content )

                                            else
                                                case String.Nonempty.fromString head of
                                                    Just nonempty2 ->
                                                        ( Language nonempty2, String.join "\n" rest )

                                                    Nothing ->
                                                        ( NoLanguage, content )

                                        [] ->
                                            ( NoLanguage, "" )
                            in
                            case String.Nonempty.fromString codeContent of
                                Just _ ->
                                    discordParseLoop source (closeIndex + 3) sourceLength modifiers "" (CodeBlock language codeContent :: flushText accText revNodes)

                                Nothing ->
                                    discordParseLoop source (closeIndex + 3) sourceLength modifiers (accText ++ "``````") revNodes

                        Nothing ->
                            case findSingleBacktick source (index + 1) sourceLength of
                                Just closeIndex ->
                                    let
                                        content =
                                            String.slice (index + 1) closeIndex source
                                    in
                                    case String.Nonempty.fromString content of
                                        Just a ->
                                            discordParseLoop source (closeIndex + 1) sourceLength modifiers "" (InlineCode (String.Nonempty.head a) (String.Nonempty.tail a) :: flushText accText revNodes)

                                        Nothing ->
                                            discordParseLoop source (closeIndex + 1) sourceLength modifiers (accText ++ "``") revNodes

                                Nothing ->
                                    discordParseLoop source (index + 1) sourceLength modifiers (accText ++ "`") revNodes

                else
                    case findSingleBacktick source (index + 1) sourceLength of
                        Just closeIndex ->
                            let
                                content =
                                    String.slice (index + 1) closeIndex source
                            in
                            case String.Nonempty.fromString content of
                                Just a ->
                                    discordParseLoop source (closeIndex + 1) sourceLength modifiers "" (InlineCode (String.Nonempty.head a) (String.Nonempty.tail a) :: flushText accText revNodes)

                                Nothing ->
                                    discordParseLoop source (closeIndex + 1) sourceLength modifiers (accText ++ "``") revNodes

                        Nothing ->
                            discordParseLoop source (index + 1) sourceLength modifiers (accText ++ "`") revNodes

            "h" ->
                case parseUrlBody False discordModifierToSymbol modifiers index source of
                    Ok url ->
                        discordParseLoop
                            source
                            (index + String.length (Url.toString url))
                            sourceLength
                            modifiers
                            ""
                            (Hyperlink url :: flushText accText revNodes)

                    Err errText ->
                        discordParseLoop
                            source
                            (index + String.length errText)
                            sourceLength
                            modifiers
                            (accText ++ errText)
                            revNodes

            "[" ->
                case parseMarkdownLink source (index + 1) sourceLength of
                    Just ( alias, url, nextIndex ) ->
                        discordParseLoop source nextIndex sourceLength modifiers "" (MarkdownLink alias url :: flushText accText revNodes)

                    Nothing ->
                        discordParseLoop source (index + 1) sourceLength modifiers (accText ++ "[") revNodes

            _ ->
                let
                    nextIndex =
                        skipDiscordNormalChars source (index + 1) sourceLength
                in
                discordParseLoop source nextIndex sourceLength modifiers (accText ++ String.slice index nextIndex source) revNodes


toDiscord :
    Nonempty (RichText (Discord.Id Discord.UserId))
    -> List (Discord.Markdown.Markdown a)
toDiscord content =
    List.map
        (\item ->
            case item of
                UserMention discordUserId ->
                    Discord.Markdown.ping discordUserId

                NormalText char string ->
                    Discord.Markdown.text (String.cons char string)

                Bold nonempty ->
                    Discord.Markdown.boldMarkdown (toDiscord nonempty)

                Italic nonempty ->
                    Discord.Markdown.italicMarkdown (toDiscord nonempty)

                Underline nonempty ->
                    Discord.Markdown.underlineMarkdown (toDiscord nonempty)

                Strikethrough nonempty ->
                    Discord.Markdown.strikethroughMarkdown (toDiscord nonempty)

                Spoiler nonempty ->
                    Discord.Markdown.spoiler (toDiscord nonempty)

                Hyperlink data ->
                    Discord.Markdown.text (Url.toString data)

                MarkdownLink alias url ->
                    Discord.Markdown.text ("[" ++ String.Nonempty.toString alias ++ "](" ++ Url.toString url ++ ")")

                InlineCode char string ->
                    Discord.Markdown.code (String.cons char string)

                CodeBlock language string ->
                    Discord.Markdown.codeBlock
                        (case language of
                            Language language2 ->
                                Just (String.Nonempty.toString language2)

                            NoLanguage ->
                                Nothing
                        )
                        string

                AttachedFile _ ->
                    Discord.Markdown.text ""

                EscapedChar char ->
                    Discord.Markdown.text (escapedCharToString char)

                Sticker _ ->
                    Discord.Markdown.text ""
        )
        (List.Nonempty.toList content)


discordParseInner :
    String
    -> Int
    -> Int
    -> List DiscordModifiers
    -> { nodes : List (RichText (Discord.Id Discord.UserId)), nextIndex : Int }
discordParseInner source index len modifiers =
    discordParseLoop source index len modifiers "" []


discordFinalizeResult :
    String
    -> List (RichText (Discord.Id Discord.UserId))
    -> List DiscordModifiers
    -> Int
    -> { nodes : List (RichText (Discord.Id Discord.UserId)), nextIndex : Int }
discordFinalizeResult accText revNodes modifiers index =
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
                        discordModifierToSymbol head
                in
                NormalText char rest :: finalNodes

            [] ->
                finalNodes
    , nextIndex = index
    }


tryParseDiscordMention : String -> Int -> Int -> Maybe ( Discord.Id Discord.UserId, Int )
tryParseDiscordMention source index len =
    let
        afterLt =
            index + 1
    in
    if afterLt < len && String.slice afterLt (afterLt + 1) source == "@" then
        let
            afterAt =
                afterLt + 1

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
        if c == "<" || c == "h" || c == "`" || c == "\\" || c == "*" || c == "_" || c == "~" || c == "|" then
            index

        else
            skipDiscordNormalChars source (index + 1) len
