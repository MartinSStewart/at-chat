module RichTextOld exposing (fromNonemptyString)

import Array exposing (Array)
import Benchmark exposing (Benchmark)
import Benchmark.Runner exposing (BenchmarkProgram)
import Dict exposing (Dict)
import FileStatus exposing (FileData, FileId)
import Id exposing (Id)
import List.Nonempty exposing (Nonempty(..))
import Parser exposing ((|.), (|=), Parser, Step(..))
import PersonName exposing (PersonName)
import RichText exposing (EscapedChar(..), Language(..), Modifiers(..), RichText(..))
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import String.Nonempty exposing (NonemptyString(..))
import Url exposing (Protocol(..), Url)


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


main : BenchmarkProgram
main =
    Benchmark.Runner.program
        (Benchmark.compare
            "Rich text parsing"
            "Old"
            (\() -> fromNonemptyString SeqDict.empty (NonemptyString '1' "234567890abcdefghijklmnopqrstuvwxyz"))
            "New"
            (\() -> RichText.fromNonemptyString SeqDict.empty (NonemptyString '1' "234567890abcdefghijklmnopqrstuvwxyz"))
        )
