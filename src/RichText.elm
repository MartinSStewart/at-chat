module RichText exposing
    ( Domain(..)
    , EscapedChar(..)
    , Language(..)
    , Modifiers(..)
    , RichText(..)
    , RichTextState
    , attachedFilePrefix
    , attachedFileSuffix
    , domainToString
    , escapedCharToString
    , fromDiscord
    , fromNonemptyString
    , hyperlinks
    , mentionsUser
    , preview
    , removeAttachedFile
    , textInputView
    , toDiscord
    , toString
    , toStringWithGetter
    , urlToDomain
    , view
    )

import Array exposing (Array)
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
import Id exposing (Id)
import List.Nonempty exposing (Nonempty(..))
import MyUi
import NonemptyDict
import NonemptyExtra
import Parser exposing ((|.), (|=), Parser, Step(..))
import PersonName exposing (PersonName)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Set exposing (Set)
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
    | InlineCode Char String
    | CodeBlock Language String
    | AttachedFile (Id FileId)
    | EscapedChar EscapedChar


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


normalTextFromString : String -> Maybe (RichText userId)
normalTextFromString text =
    case String.uncons text of
        Just ( head, rest ) ->
            NormalText head rest |> Just

        Nothing ->
            Nothing


normalTextFromNonempty : NonemptyString -> RichText userId
normalTextFromNonempty text =
    NormalText (String.Nonempty.head text) (String.Nonempty.tail text)


removeAttachedFile : Id FileId -> Nonempty (RichText userId) -> Maybe (Nonempty (RichText userId))
removeAttachedFile fileId list =
    List.filterMap
        (\richText ->
            case richText of
                NormalText _ _ ->
                    Just richText

                UserMention _ ->
                    Just richText

                Bold nonempty ->
                    removeAttachedFile fileId nonempty |> Maybe.map Bold

                Italic nonempty ->
                    removeAttachedFile fileId nonempty |> Maybe.map Italic

                Underline nonempty ->
                    removeAttachedFile fileId nonempty |> Maybe.map Underline

                Strikethrough nonempty ->
                    removeAttachedFile fileId nonempty |> Maybe.map Strikethrough

                Spoiler nonempty ->
                    removeAttachedFile fileId nonempty |> Maybe.map Spoiler

                Hyperlink _ ->
                    Just richText

                InlineCode _ _ ->
                    Just richText

                CodeBlock _ _ ->
                    Just richText

                AttachedFile id ->
                    if id == fileId then
                        Nothing

                    else
                        Just richText

                EscapedChar _ ->
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
        )
        nonempty
        |> List.Nonempty.toList
        |> String.concat


toString : SeqDict userId { a | name : PersonName } -> Nonempty (RichText userId) -> String
toString users nonempty =
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
                    "*" ++ toString users a ++ "*"

                Italic a ->
                    "_" ++ toString users a ++ "_"

                Underline a ->
                    "__" ++ toString users a ++ "__"

                Strikethrough a ->
                    "~~" ++ toString users a ++ "~~"

                Spoiler a ->
                    "||" ++ toString users a ++ "||"

                Hyperlink data ->
                    Url.toString data

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
        )
        nonempty
        |> List.Nonempty.toList
        |> String.concat


fromNonemptyString : SeqDict userId { a | name : PersonName } -> NonemptyString -> Nonempty (RichText userId)
fromNonemptyString users string =
    case Parser.run (parser users []) (String.Nonempty.toString string) of
        Ok ok ->
            case List.Nonempty.fromList (Array.toList ok) of
                Just nonempty ->
                    normalize nonempty

                Nothing ->
                    Nonempty (normalTextFromNonempty string) []

        Err _ ->
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

                InlineCode char string ->
                    List.Nonempty.cons (InlineCode char string) nonempty2

                CodeBlock language string ->
                    List.Nonempty.cons (CodeBlock language string) nonempty2

                AttachedFile fileId ->
                    List.Nonempty.cons (AttachedFile fileId) nonempty2

                EscapedChar char ->
                    List.Nonempty.cons (EscapedChar char) nonempty2
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

                InlineCode char string ->
                    InlineCode char string

                CodeBlock language string ->
                    CodeBlock language string

                AttachedFile fileId ->
                    AttachedFile fileId

                EscapedChar char ->
                    EscapedChar char
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


type alias LoopState userId =
    { current : Array String, rest : Array (RichText userId) }


charToEscaped : Dict String EscapedChar
charToEscaped =
    List.map (\escaped -> ( escapedCharToString escaped, escaped )) allEscapedChars |> Dict.fromList


discordEscapableChars : Set String
discordEscapableChars =
    Set.fromList [ "\\", "*", ">", "`", "~", "@" ]


parser : SeqDict userId { a | name : PersonName } -> List Modifiers -> Parser (Array (RichText userId))
parser users modifiers =
    Parser.loop
        { current = Array.empty, rest = Array.empty }
        (\state ->
            Parser.oneOf
                [ Parser.succeed
                    (\text ->
                        case Dict.get text charToEscaped of
                            Just escaped ->
                                Loop
                                    { current = Array.empty
                                    , rest =
                                        Array.append state.rest (Array.push (EscapedChar escaped) (parserHelper state))
                                    }

                            Nothing ->
                                Loop { current = Array.push ("\\" ++ text) state.current, rest = state.rest }
                    )
                    |. Parser.symbol "\\"
                    |= (Parser.chompIf (\_ -> True) |> Parser.getChompedString)
                , Parser.succeed identity
                    |. Parser.symbol "@"
                    |= Parser.oneOf
                        ((SeqDict.toList users
                            |> List.sortBy (\( _, user ) -> PersonName.toString user.name |> String.length |> negate)
                            |> List.map
                                (\( userId, user ) ->
                                    Parser.succeed
                                        (Loop
                                            { current = Array.empty
                                            , rest =
                                                Array.append
                                                    state.rest
                                                    (Array.push (UserMention userId) (parserHelper state))
                                            }
                                        )
                                        |. Parser.symbol (PersonName.toString user.name)
                                )
                         )
                            ++ [ Parser.succeed
                                    (Loop
                                        { current = Array.push "@" state.current
                                        , rest = state.rest
                                        }
                                    )
                               ]
                        )
                , modifierHelper users True IsBold Bold state modifiers
                , modifierHelper users False IsUnderlined Underline state modifiers
                , modifierHelper users False IsItalic Italic state modifiers
                , modifierHelper users False IsStrikethrough Strikethrough state modifiers
                , modifierHelper users False IsSpoilered Spoiler state modifiers
                , Parser.succeed
                    (\( language, text ) ->
                        case String.Nonempty.fromString text of
                            Just _ ->
                                Loop
                                    { current = Array.empty
                                    , rest =
                                        Array.append
                                            state.rest
                                            (Array.push
                                                (CodeBlock language text)
                                                (parserHelper state)
                                            )
                                    }

                            Nothing ->
                                Loop
                                    { current = Array.push "``````" state.current
                                    , rest = state.rest
                                    }
                    )
                    |= codeBlockParser
                    |> Parser.backtrackable
                , Parser.succeed
                    (\text ->
                        case String.Nonempty.fromString text of
                            Just a ->
                                Loop
                                    { current = Array.empty
                                    , rest =
                                        Array.append
                                            state.rest
                                            (Array.push
                                                (InlineCode (String.Nonempty.head a) (String.Nonempty.tail a))
                                                (parserHelper state)
                                            )
                                    }

                            Nothing ->
                                Loop
                                    { current = Array.push "``" state.current
                                    , rest = state.rest
                                    }
                    )
                    |. Parser.symbol "`"
                    |= (Parser.chompWhile (\char -> char /= '`') |> Parser.getChompedString)
                    |. Parser.symbol "`"
                    |> Parser.backtrackable
                , urlParser
                    |> Parser.map
                        (\{ hyperlink, trailing } ->
                            (case hyperlink of
                                Ok hyperlink2 ->
                                    { current = Array.fromList [ trailing ]
                                    , rest =
                                        Array.append
                                            state.rest
                                            (Array.push (Hyperlink hyperlink2) (parserHelper state))
                                    }

                                Err text ->
                                    { current = Array.push (text ++ trailing) state.current
                                    , rest = state.rest
                                    }
                            )
                                |> Loop
                        )
                , Parser.succeed identity
                    |. Parser.symbol attachedFilePrefix
                    |= Parser.int
                    |. Parser.symbol attachedFileSuffix
                    |> Parser.backtrackable
                    |> Parser.map
                        (\int ->
                            { current = Array.empty
                            , rest =
                                Array.append
                                    state.rest
                                    (Array.push (AttachedFile (Id.fromInt int)) (parserHelper state))
                            }
                                |> Loop
                        )
                , Parser.chompIf (\_ -> True)
                    |> Parser.andThen
                        (\_ ->
                            Parser.chompWhile
                                (\char ->
                                    case char of
                                        '[' ->
                                            False

                                        '@' ->
                                            False

                                        'h' ->
                                            False

                                        '`' ->
                                            False

                                        '\\' ->
                                            False

                                        '*' ->
                                            False

                                        '_' ->
                                            False

                                        '~' ->
                                            False

                                        '|' ->
                                            False

                                        _ ->
                                            True
                                )
                        )
                    |> Parser.getChompedString
                    |> Parser.map
                        (\a ->
                            Loop
                                { current = Array.push a state.current
                                , rest = state.rest
                                }
                        )
                , Parser.map (\() -> bailOut state modifiers) Parser.end
                ]
        )


urlParser : Parser { hyperlink : Result String Url, trailing : String }
urlParser =
    Parser.succeed
        (\protocol url ->
            let
                urlLength : Int
                urlLength =
                    String.length url

                ( index, _ ) =
                    String.foldr
                        (\char (( index2, stop ) as state) ->
                            if stop then
                                state

                            else if char == '.' || char == ')' || char == ',' || char == '"' then
                                ( index2 - 1, False )

                            else
                                ( index2, True )
                        )
                        ( urlLength, False )
                        url

                urlText : String
                urlText =
                    (case protocol of
                        Http ->
                            "http://"

                        Https ->
                            "https://"
                    )
                        ++ String.slice 0 index url
            in
            { hyperlink =
                case Url.fromString urlText of
                    Just url2 ->
                        let
                            url3 =
                                { url2 | protocol = protocol }

                            urlNoPath =
                                { url3 | path = "" }
                        in
                        -- This is a hack to get the url decode to exactly match the user's input
                        -- Otherwise what the user is typing will get out of sync in the case they type http://google.com?query and it gets decoded to http://google.com/?query
                        if Url.toString urlNoPath == urlText then
                            Ok urlNoPath

                        else
                            Ok url3

                    Nothing ->
                        Err urlText
            , trailing = String.slice index urlLength url
            }
        )
        |= Parser.oneOf
            [ Parser.symbol "http://" |> Parser.map (\_ -> Url.Http)
            , Parser.symbol "https://" |> Parser.map (\_ -> Url.Https)
            ]
        |= (Parser.chompWhile
                (\char ->
                    (char /= ' ')
                        && (char /= '\n')
                        && (char /= '\t')
                        && (char /= '<')
                        {- The | char (along with _ and *) should be allowed in urls and only included in trailing if there's a modifier that uses them.
                           That's complicated though so for now just having | to catch the common case of spoilering a url is good enough)
                        -}
                        && (char /= '|')
                )
                |> Parser.getChompedString
           )


attachedFilePrefix : String
attachedFilePrefix =
    "[!"


attachedFileSuffix : String
attachedFileSuffix =
    "]"


codeBlockParser : Parser ( Language, String )
codeBlockParser =
    Parser.succeed
        (\text ->
            case String.split "\n" text of
                [ single ] ->
                    ( NoLanguage, single )

                head :: rest ->
                    if String.contains " " head then
                        ( NoLanguage, text )

                    else
                        case String.Nonempty.fromString head of
                            Just nonempty ->
                                ( Language nonempty, String.join "\n" rest )

                            Nothing ->
                                ( NoLanguage, text )

                [] ->
                    ( NoLanguage, "" )
        )
        |. Parser.symbol "```"
        |= Parser.loop
            []
            (\list ->
                Parser.oneOf
                    [ Parser.succeed (Done (List.reverse list |> String.concat))
                        |. Parser.symbol "```"
                    , Parser.succeed (\char -> Loop (char :: list))
                        |= (Parser.chompIf (\_ -> True) |> Parser.getChompedString)
                    ]
            )


bailOut : LoopState userId -> List Modifiers -> Step state (Array (RichText userId))
bailOut state modifiers =
    Array.append
        (case modifiers of
            head :: _ ->
                let
                    (NonemptyString char rest) =
                        modifierToSymbol head
                in
                Array.fromList [ NormalText char rest ]

            [] ->
                Array.empty
        )
        (Array.append state.rest (parserHelper state))
        |> Done


getRemainingText : Parser String
getRemainingText =
    Parser.succeed String.dropLeft
        |= Parser.getOffset
        |= Parser.getSource


modifierHelper :
    SeqDict userId { a | name : PersonName }
    -> Bool
    -> Modifiers
    -> (Nonempty (RichText userId) -> RichText userId)
    -> LoopState userId
    -> List Modifiers
    -> Parser (Step (LoopState userId) (Array (RichText userId)))
modifierHelper users noTrailingWhitespace modifier container state modifiers =
    let
        symbol : NonemptyString
        symbol =
            modifierToSymbol modifier

        symbolText =
            String.Nonempty.toString symbol
    in
    if List.head modifiers == Just modifier then
        Parser.map
            (\() ->
                case
                    Array.append state.rest (parserHelper state)
                        |> Array.toList
                        |> List.Nonempty.fromList
                of
                    Just nonempty ->
                        Done (Array.fromList [ container nonempty ])

                    Nothing ->
                        NormalText (String.Nonempty.head symbol) (String.Nonempty.tail symbol)
                            |> List.singleton
                            |> Array.fromList
                            |> Done
            )
            (Parser.symbol symbolText)

    else if List.member modifier modifiers then
        getRemainingText
            |> Parser.andThen
                (\remainingText ->
                    if String.startsWith symbolText remainingText then
                        bailOut state modifiers |> Parser.succeed

                    else
                        Parser.backtrackable (Parser.problem "")
                )

    else
        Parser.succeed identity
            |. Parser.symbol symbolText
            |= Parser.oneOf
                [ if noTrailingWhitespace then
                    getRemainingText
                        |> Parser.andThen
                            (\remainingText ->
                                if
                                    String.startsWith symbolText remainingText
                                        || String.startsWith " " remainingText
                                then
                                    Parser.backtrackable (Parser.problem "")

                                else
                                    Parser.map
                                        (\a ->
                                            Loop
                                                { current = Array.empty
                                                , rest = Array.append state.rest (Array.append (parserHelper state) a)
                                                }
                                        )
                                        (parser users (modifier :: modifiers))
                            )

                  else
                    Parser.map
                        (\a ->
                            Loop
                                { current = Array.empty
                                , rest = Array.append state.rest (Array.append (parserHelper state) a)
                                }
                        )
                        (parser users (modifier :: modifiers))
                , Loop { current = Array.push symbolText state.current, rest = state.rest }
                    |> Parser.succeed
                ]


parserHelper : LoopState userId -> Array (RichText userId)
parserHelper state =
    case state.current |> Array.toList |> String.concat |> normalTextFromString of
        Just a ->
            Array.fromList [ a ]

        Nothing ->
            Array.empty


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

                InlineCode _ _ ->
                    set2

                CodeBlock _ _ ->
                    set2

                AttachedFile _ ->
                    set2

                EscapedChar _ ->
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
    -> SeqSet Domain
    -> (Int -> msg)
    -> SeqSet Int
    -> SeqDict userId { a | name : PersonName }
    -> SeqDict (Id FileId) FileData
    -> Array Embed
    -> Nonempty (RichText userId)
    -> List (Html msg)
view htmlIdPrefix containerWidth onPressLink domainWhitelist onPressSpoiler revealedSpoilers users attachedFiles embeds nonempty =
    viewHelper
        (ShowLargeContent containerWidth)
        (Just ( htmlIdPrefix, onPressSpoiler ))
        onPressLink
        domainWhitelist
        0
        { spoiler = False, underline = False, italic = False, bold = False, strikethrough = False }
        revealedSpoilers
        users
        attachedFiles
        embeds
        0
        nonempty
        |> (\( _, _, a ) -> a)


preview :
    (Url -> msg)
    -> SeqSet Domain
    -> SeqSet Int
    -> SeqDict userId { a | name : PersonName }
    -> SeqDict (Id FileId) FileData
    -> Nonempty (RichText userId)
    -> List (Html msg)
preview onPressLink domainWhitelist revealedSpoilers users attachedFiles nonempty =
    viewHelper
        NoLargeContent
        Nothing
        onPressLink
        domainWhitelist
        0
        { spoiler = False, underline = False, italic = False, bold = False, strikethrough = False }
        revealedSpoilers
        users
        attachedFiles
        Array.empty
        0
        nonempty
        |> (\( _, _, a ) -> a)


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
    -> SeqSet Domain
    -> Int
    -> RichTextState
    -> SeqSet Int
    -> SeqDict userId { a | name : PersonName }
    -> SeqDict (Id FileId) FileData
    -> Array Embed
    -> Int
    -> Nonempty (RichText userId)
    -> ( Int, Int, List (Html msg) )
viewHelper showLargeContent maybePressedSpoiler onPressLink domainWhitelist spoilerIndex state revealedSpoilers allUsers attachedFiles embeds embedIndex nonempty =
    List.foldl
        (\item ( spoilerIndex2, embedIndex2, currentList ) ->
            case item of
                UserMention userId ->
                    ( spoilerIndex2, embedIndex2, currentList ++ [ MyUi.userLabelHtml userId allUsers ] )

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
                                domainWhitelist
                                spoilerIndex2
                                { state | italic = True }
                                revealedSpoilers
                                allUsers
                                attachedFiles
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
                                domainWhitelist
                                spoilerIndex2
                                { state | underline = True }
                                revealedSpoilers
                                allUsers
                                attachedFiles
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
                                domainWhitelist
                                spoilerIndex2
                                { state | bold = True }
                                revealedSpoilers
                                allUsers
                                attachedFiles
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
                                domainWhitelist
                                spoilerIndex2
                                { state | strikethrough = True }
                                revealedSpoilers
                                allUsers
                                attachedFiles
                                embeds
                                embedIndex2
                                nonempty2
                    in
                    ( spoilerIndex3, embedIndex3, currentList ++ list )

                Spoiler nonempty2 ->
                    let
                        revealed =
                            SeqSet.member spoilerIndex2 revealedSpoilers

                        -- Ignore the spoiler index value. It shouldn't be possible to have nested spoilers
                        ( _, embedIndex3, list ) =
                            viewHelper
                                showLargeContent
                                maybePressedSpoiler
                                onPressLink
                                domainWhitelist
                                spoilerIndex2
                                (if revealed then
                                    state

                                 else
                                    { state | spoiler = True }
                                )
                                revealedSpoilers
                                allUsers
                                attachedFiles
                                embeds
                                embedIndex2
                                nonempty2
                    in
                    ( spoilerIndex2 + 1
                    , embedIndex3
                    , currentList
                        ++ [ Html.span
                                ([ Html.Attributes.style "padding" "0 2px 0 2px"
                                 , Html.Attributes.style "border-radius" "2px"
                                 ]
                                    ++ (if revealed then
                                            [ Html.Attributes.style "background" "rgb(30,30,30)" ]

                                        else
                                            [ Html.Attributes.style "cursor" "pointer"
                                            , Html.Attributes.style "background" "rgb(0,0,0)"
                                            ]
                                                ++ (case maybePressedSpoiler of
                                                        Just ( htmlIdPrefix, pressedSpoiler ) ->
                                                            [ Html.Events.onClick (pressedSpoiler spoilerIndex2)
                                                            , Html.Attributes.id (Dom.idToString htmlIdPrefix ++ "_" ++ String.fromInt spoilerIndex2)
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
                                    [ htmlAttrIf state.italic (Html.Attributes.style "font-style" "oblique")
                                    , htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                                    , htmlAttrIf state.bold (Html.Attributes.style "font-weight" "700")
                                    , htmlAttrIf state.strikethrough (Html.Attributes.style "text-decoration" "line-through")
                                    , Html.Attributes.style "opacity" "0"
                                    ]
                                    [ Html.text text ]

                             else
                                case Array.get embedIndex2 embeds of
                                    Just EmbedLoading ->
                                        embedLoadingView onPressLink domainWhitelist data

                                    Just (EmbedLoaded embed) ->
                                        case ( embed == Embed.empty, showLargeContent ) of
                                            ( False, ShowLargeContent containerWidth ) ->
                                                embedView onPressLink containerWidth domainWhitelist data embed

                                            _ ->
                                                inlineEmbedView showLargeContent onPressLink domainWhitelist data

                                    Nothing ->
                                        inlineEmbedView showLargeContent onPressLink domainWhitelist data
                           ]
                    )

                InlineCode char rest ->
                    ( spoilerIndex2
                    , embedIndex2
                    , currentList
                        ++ [ Html.span
                                [ htmlAttrIf state.italic (Html.Attributes.style "font-style" "oblique")
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
                                        [ Html.Attributes.style "background-color" "rgb(90,100,120)"
                                        , Html.Attributes.style "border" "rgb(55,61,73) solid 1px"
                                        , Html.Attributes.style "padding" "0 4px 0 4px"
                                        , Html.Attributes.style "border-radius" "4px"
                                        , Html.Attributes.style "font-family" "monospace"
                                        ]
                                        [ Html.text text ]
                                   ]
                            )

                        NoLargeContent ->
                            ( spoilerIndex2, embedIndex2, currentList ++ [ Html.text "<...>" ] )

                AttachedFile fileId ->
                    case showLargeContent of
                        ShowLargeContent containerWidth2 ->
                            ( spoilerIndex2
                            , embedIndex2
                            , case SeqDict.get fileId attachedFiles of
                                Just fileData ->
                                    currentList
                                        ++ [ case fileData.imageMetadata of
                                                Just { imageSize } ->
                                                    let
                                                        fileUrl =
                                                            FileStatus.fileUrl fileData.contentType fileData.fileHash

                                                        thumbnailUrl =
                                                            FileStatus.thumbnailUrl
                                                                imageSize
                                                                fileData.contentType
                                                                fileData.fileHash

                                                        ( width, height ) =
                                                            actualImageSize FileStatus.imageMaxHeight containerWidth2 imageSize
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
                                                    fileDownloadView fileData
                                           ]

                                Nothing ->
                                    currentList ++ normalTextView (attachedFilePrefix ++ Id.toString fileId ++ attachedFileSuffix) state
                            )

                        NoLargeContent ->
                            ( spoilerIndex2, embedIndex2, currentList ++ [ Icons.image ] )

                EscapedChar char ->
                    ( spoilerIndex2, embedIndex2, currentList ++ [ Html.text (escapedCharToString char) ] )
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


embedView : (Url -> msg) -> Int -> SeqSet Domain -> Url -> EmbedData -> Html msg
embedView onPressLink containerWidth domainWhitelist url embed =
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
                    in
                    Html.img
                        [ Html.Attributes.src imageData.url
                        , Html.Attributes.style "width" (String.fromFloat width ++ "px")
                        , Html.Attributes.style "height" (String.fromFloat height ++ "px")
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



--buttonOrA
--    onPressUrl
--    domainWhitelist
--    url
--    [ htmlAttrIf state.italic (Html.Attributes.style "font-style" "oblique")
--    , htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
--    , htmlAttrIf state.bold (Html.Attributes.style "font-weight" "700")
--    , htmlAttrIf state.strikethrough (Html.Attributes.style "text-decoration" "line-through")
--    ]
--    [ Html.text urlText ]


fileDownloadView : FileData -> Html msg
fileDownloadView fileData =
    let
        fileUrl =
            FileStatus.fileUrl fileData.contentType fileData.fileHash
    in
    Html.a
        [ Html.Attributes.style "max-width" "284px"
        , Html.Attributes.style "background-color" (MyUi.colorToStyle MyUi.background1)
        , Html.Attributes.style "border-radius" "4px"
        , Html.Attributes.style "border" ("solid 1px " ++ MyUi.colorToStyle MyUi.border1)
        , Html.Attributes.style "display" "block"
        , Html.Attributes.href fileUrl
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
            ]
            [ Icons.download ]
        ]


textInputView :
    SeqDict userId { a | name : PersonName }
    -> SeqDict (Id FileId) b
    -> Nonempty (RichText userId)
    -> List (Html msg)
textInputView users attachedFiles nonempty =
    textInputViewHelper
        { underline = False, italic = False, bold = False, strikethrough = False, spoiler = False }
        users
        attachedFiles
        nonempty


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
    -> Nonempty (RichText userId)
    -> List (Html msg)
textInputViewHelper state allUsers attachedFiles nonempty =
    List.concatMap
        (\item ->
            case item of
                UserMention userId ->
                    [ case SeqDict.get userId allUsers of
                        Just user ->
                            Html.span
                                [ Html.Attributes.style "color" "rgb(215,235,255)"
                                , Html.Attributes.style "background-color" "rgba(57,77,255,0.5)"
                                , Html.Attributes.style "border-radius" "2px"
                                ]
                                [ Html.text ("@" ++ PersonName.toString user.name) ]

                        Nothing ->
                            Html.text ""
                    ]

                NormalText char text ->
                    [ Html.span
                        [ --htmlAttrIf state.italic (Html.Attributes.style "font-style" "oblique")
                          htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                        , htmlAttrIf state.bold (Html.Attributes.style "text-shadow" "0.7px 0px 0px white")
                        , htmlAttrIf state.strikethrough (Html.Attributes.style "text-decoration" "line-through")
                        , htmlAttrIf state.spoiler (Html.Attributes.style "background-color" "rgb(0,0,0)")
                        ]
                        [ Html.text (String.cons char text) ]
                    ]

                Italic nonempty2 ->
                    formatText "_"
                        :: textInputViewHelper
                            { state | italic = True }
                            allUsers
                            attachedFiles
                            nonempty2
                        ++ [ formatText "_" ]

                Underline nonempty2 ->
                    formatText "__"
                        :: textInputViewHelper
                            { state | underline = True }
                            allUsers
                            attachedFiles
                            nonempty2
                        ++ [ formatText "__" ]

                Bold nonempty2 ->
                    formatText "*"
                        :: textInputViewHelper
                            { state | bold = True }
                            allUsers
                            attachedFiles
                            nonempty2
                        ++ [ formatText "*" ]

                Strikethrough nonempty2 ->
                    formatText "~~"
                        :: textInputViewHelper
                            { state | strikethrough = True }
                            allUsers
                            attachedFiles
                            nonempty2
                        ++ [ formatText "~~" ]

                Spoiler nonempty2 ->
                    formatText "||"
                        :: textInputViewHelper
                            { state | spoiler = True }
                            allUsers
                            attachedFiles
                            nonempty2
                        ++ [ formatText "||" ]

                Hyperlink data ->
                    [ Html.span
                        [ htmlAttrIf state.italic (Html.Attributes.style "font-style" "oblique")
                        , htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                        , htmlAttrIf state.bold (Html.Attributes.style "text-shadow" "0.7px 0px 0px white")
                        , htmlAttrIf state.strikethrough (Html.Attributes.style "text-decoration" "line-through")
                        , htmlAttrIf state.spoiler (Html.Attributes.style "background-color" "rgb(0,0,0)")
                        , Html.Attributes.style "color" "rgb(66,93,203)"
                        ]
                        [ Html.text (Url.toString data) ]
                    ]

                InlineCode char rest ->
                    [ formatText "`"
                    , Html.span
                        [ htmlAttrIf state.italic (Html.Attributes.style "font-style" "oblique")
                        , htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
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

                CodeBlock language string ->
                    [ formatText
                        ("```"
                            ++ (case language of
                                    Language language2 ->
                                        String.Nonempty.toString language2 ++ "\n"

                                    NoLanguage ->
                                        ""
                               )
                        )
                    , Html.text string
                    , formatText "```"
                    ]

                AttachedFile fileId ->
                    let
                        text : String
                        text =
                            attachedFilePrefix ++ Id.toString fileId ++ attachedFileSuffix
                    in
                    [ if SeqDict.member fileId attachedFiles then
                        formatText text

                      else
                        Html.text text
                    ]

                EscapedChar char ->
                    [ formatText "\\", Html.text (escapedCharToString char) ]
        )
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


fromDiscord : String -> SeqDict (Id FileId) FileData -> Nonempty (RichText (Discord.Id Discord.UserId))
fromDiscord text attachments =
    case String.Nonempty.fromString text of
        Just nonempty ->
            NonemptyExtra.appendList
                (case Parser.run (discordParser []) text of
                    Ok ok ->
                        case List.Nonempty.fromList (Array.toList ok) of
                            Just nonempty2 ->
                                normalize nonempty2

                            Nothing ->
                                Nonempty (normalTextFromNonempty nonempty) []

                    Err _ ->
                        Nonempty (normalTextFromNonempty nonempty) []
                )
                (List.map AttachedFile (SeqDict.keys attachments))

        Nothing ->
            case NonemptyDict.fromSeqDict attachments of
                Just attachments2 ->
                    List.Nonempty.map AttachedFile (NonemptyDict.keys attachments2)

                Nothing ->
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
discordParser : List DiscordModifiers -> Parser (Array (RichText (Discord.Id Discord.UserId)))
discordParser modifiers =
    Parser.loop
        { current = Array.empty, rest = Array.empty }
        (\state ->
            Parser.oneOf
                [ Parser.succeed
                    (\text ->
                        if Set.member text discordEscapableChars then
                            Loop { current = Array.push text state.current, rest = state.rest }

                        else
                            Loop { current = Array.push ("\\" ++ text) state.current, rest = state.rest }
                    )
                    |. Parser.symbol "\\"
                    |= (Parser.chompIf (\_ -> True) |> Parser.getChompedString)
                , Parser.succeed
                    (\digits ->
                        case UInt64.fromString digits of
                            Just discordUserId ->
                                Loop
                                    { current = Array.empty
                                    , rest =
                                        Array.append
                                            state.rest
                                            (Array.push
                                                (UserMention (Discord.idFromUInt64 discordUserId))
                                                (parserHelper state)
                                            )
                                    }

                            Nothing ->
                                Loop
                                    { current = Array.push ("<@" ++ digits ++ ">") state.current
                                    , rest = state.rest
                                    }
                    )
                    |. Parser.symbol "<@"
                    |. Parser.oneOf
                        [ Parser.symbol "!"
                        , Parser.succeed ()
                        ]
                    |= (Parser.chompWhile Char.isDigit |> Parser.getChompedString)
                    |. Parser.symbol ">"
                    |> Parser.backtrackable
                , discordModifierHelper False DiscordIsBold Bold state modifiers
                , discordModifierHelper False DiscordIsUnderlined Underline state modifiers
                , discordModifierHelper True DiscordIsItalic Italic state modifiers
                , discordModifierHelper False DiscordIsItalic2 Italic state modifiers
                , discordModifierHelper False DiscordIsStrikethrough Strikethrough state modifiers
                , discordModifierHelper False DiscordIsSpoilered Spoiler state modifiers
                , Parser.succeed
                    (\( language, text ) ->
                        case String.Nonempty.fromString text of
                            Just _ ->
                                Loop
                                    { current = Array.empty
                                    , rest =
                                        Array.append
                                            state.rest
                                            (Array.push
                                                (CodeBlock language text)
                                                (parserHelper state)
                                            )
                                    }

                            Nothing ->
                                Loop
                                    { current = Array.push "``````" state.current
                                    , rest = state.rest
                                    }
                    )
                    |= codeBlockParser
                    |> Parser.backtrackable
                , Parser.succeed
                    (\text ->
                        case String.Nonempty.fromString text of
                            Just a ->
                                Loop
                                    { current = Array.empty
                                    , rest =
                                        Array.append
                                            state.rest
                                            (Array.push
                                                (InlineCode (String.Nonempty.head a) (String.Nonempty.tail a))
                                                (parserHelper state)
                                            )
                                    }

                            Nothing ->
                                Loop
                                    { current = Array.push "``" state.current
                                    , rest = state.rest
                                    }
                    )
                    |. Parser.symbol "`"
                    |= (Parser.chompWhile (\char -> char /= '`') |> Parser.getChompedString)
                    |. Parser.symbol "`"
                    |> Parser.backtrackable
                , urlParser
                    |> Parser.map
                        (\{ hyperlink, trailing } ->
                            (case hyperlink of
                                Ok hyperlink2 ->
                                    { current = Array.fromList [ trailing ]
                                    , rest =
                                        Array.append
                                            state.rest
                                            (Array.push (Hyperlink hyperlink2) (parserHelper state))
                                    }

                                Err text ->
                                    { current = Array.push (text ++ trailing) state.current
                                    , rest = state.rest
                                    }
                            )
                                |> Loop
                        )
                , Parser.chompIf (\_ -> True)
                    |> Parser.andThen
                        (\_ ->
                            Parser.chompWhile
                                (\char ->
                                    case char of
                                        '<' ->
                                            False

                                        'h' ->
                                            False

                                        '`' ->
                                            False

                                        '\\' ->
                                            False

                                        '*' ->
                                            False

                                        '_' ->
                                            False

                                        '~' ->
                                            False

                                        '|' ->
                                            False

                                        _ ->
                                            True
                                )
                        )
                    |> Parser.getChompedString
                    |> Parser.map
                        (\a ->
                            Loop
                                { current = Array.push a state.current
                                , rest = state.rest
                                }
                        )
                , Parser.map (\() -> discordBailOut state modifiers) Parser.end
                ]
        )


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
        )
        (List.Nonempty.toList content)


discordModifierHelper :
    Bool
    -> DiscordModifiers
    -> (Nonempty (RichText (Discord.Id Discord.UserId)) -> RichText (Discord.Id Discord.UserId))
    -> LoopState (Discord.Id Discord.UserId)
    -> List DiscordModifiers
    -> Parser (Step (LoopState (Discord.Id Discord.UserId)) (Array (RichText (Discord.Id Discord.UserId))))
discordModifierHelper noTrailingWhitespace modifier container state modifiers =
    let
        symbol : NonemptyString
        symbol =
            discordModifierToSymbol modifier

        symbolText =
            String.Nonempty.toString symbol
    in
    if List.head modifiers == Just modifier then
        Parser.map
            (\() ->
                case
                    Array.append state.rest (parserHelper state)
                        |> Array.toList
                        |> List.Nonempty.fromList
                of
                    Just nonempty ->
                        Done (Array.fromList [ container nonempty ])

                    Nothing ->
                        NormalText (String.Nonempty.head symbol) (String.Nonempty.tail symbol)
                            |> List.singleton
                            |> Array.fromList
                            |> Done
            )
            (Parser.symbol symbolText)

    else if List.member modifier modifiers then
        getRemainingText
            |> Parser.andThen
                (\remainingText ->
                    if String.startsWith symbolText remainingText then
                        discordBailOut state modifiers |> Parser.succeed

                    else
                        Parser.backtrackable (Parser.problem "")
                )

    else
        Parser.succeed identity
            |. Parser.symbol symbolText
            |= Parser.oneOf
                [ if noTrailingWhitespace then
                    getRemainingText
                        |> Parser.andThen
                            (\remainingText ->
                                if
                                    String.startsWith symbolText remainingText
                                        || String.startsWith " " remainingText
                                then
                                    Parser.backtrackable (Parser.problem "")

                                else
                                    Parser.map
                                        (\a ->
                                            Loop
                                                { current = Array.empty
                                                , rest = Array.append state.rest (Array.append (parserHelper state) a)
                                                }
                                        )
                                        (discordParser (modifier :: modifiers))
                            )

                  else
                    Parser.map
                        (\a ->
                            Loop
                                { current = Array.empty
                                , rest = Array.append state.rest (Array.append (parserHelper state) a)
                                }
                        )
                        (discordParser (modifier :: modifiers))
                , Loop { current = Array.push symbolText state.current, rest = state.rest }
                    |> Parser.succeed
                ]


discordBailOut :
    LoopState (Discord.Id Discord.UserId)
    -> List DiscordModifiers
    -> Step state (Array (RichText (Discord.Id Discord.UserId)))
discordBailOut state modifiers =
    Array.append
        (case modifiers of
            head :: _ ->
                let
                    (NonemptyString char rest) =
                        discordModifierToSymbol head
                in
                Array.fromList [ NormalText char rest ]

            [] ->
                Array.empty
        )
        (Array.append state.rest (parserHelper state))
        |> Done
