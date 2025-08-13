module RichText exposing
    ( Language(..)
    , RichText(..)
    , RichTextState
    , append
    , attachedFilePrefix
    , attachedFileSuffix
    , fromNonemptyString
    , mentionsUser
    , preview
    , removeAttachedFile
    , textInputView
    , toDiscord
    , toString
    , view
    )

import Array exposing (Array)
import Coord
import Discord.Id
import Discord.Markdown
import FileName
import FileStatus exposing (FileData, FileId)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Icons
import Id exposing (Id, UserId)
import List.Nonempty exposing (Nonempty(..))
import MyUi
import OneToOne exposing (OneToOne)
import Parser exposing ((|.), (|=), Parser, Step(..))
import PersonName exposing (PersonName)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import String.Nonempty exposing (NonemptyString(..))
import Url exposing (Protocol(..))


type RichText
    = UserMention (Id UserId)
    | NormalText Char String
    | Bold (Nonempty RichText)
    | Italic (Nonempty RichText)
    | Underline (Nonempty RichText)
    | Strikethrough (Nonempty RichText)
    | Spoiler (Nonempty RichText)
    | Hyperlink Protocol String
    | InlineCode Char String
    | CodeBlock Language String
    | AttachedFile (Id FileId)


type Language
    = Language NonemptyString
    | None


normalTextFromString : String -> Maybe RichText
normalTextFromString text =
    case String.uncons text of
        Just ( head, rest ) ->
            NormalText head rest |> Just

        Nothing ->
            Nothing


normalTextFromNonempty : NonemptyString -> RichText
normalTextFromNonempty text =
    NormalText (String.Nonempty.head text) (String.Nonempty.tail text)


removeAttachedFile : Id FileId -> Nonempty RichText -> Maybe (Nonempty RichText)
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

                Hyperlink _ _ ->
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
        )
        (List.Nonempty.toList list)
        |> List.Nonempty.fromList


toString : SeqDict (Id UserId) { a | name : PersonName } -> Nonempty RichText -> String
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

                Hyperlink protocol rest ->
                    hyperlinkToString protocol rest

                InlineCode char rest ->
                    "`" ++ String.cons char rest ++ "`"

                CodeBlock language string ->
                    "```"
                        ++ (case language of
                                Language unknown ->
                                    String.Nonempty.toString unknown ++ "\n"

                                None ->
                                    ""
                           )
                        ++ string
                        ++ "```"

                AttachedFile fileId ->
                    attachedFilePrefix ++ Id.toString fileId ++ attachedFileSuffix
        )
        nonempty
        |> List.Nonempty.toList
        |> String.concat


append : Nonempty RichText -> Nonempty RichText -> Nonempty RichText
append first second =
    List.Nonempty.append first second |> normalize


fromNonemptyString : SeqDict (Id UserId) { a | name : PersonName } -> NonemptyString -> Nonempty RichText
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


normalize : Nonempty RichText -> Nonempty RichText
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

                Hyperlink protocol rest ->
                    List.Nonempty.cons (Hyperlink protocol rest) nonempty2

                InlineCode char string ->
                    List.Nonempty.cons (InlineCode char string) nonempty2

                CodeBlock language string ->
                    List.Nonempty.cons (CodeBlock language string) nonempty2

                AttachedFile fileId ->
                    List.Nonempty.cons (AttachedFile fileId) nonempty2
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

                Hyperlink protocol rest ->
                    Hyperlink protocol rest

                InlineCode char string ->
                    InlineCode char string

                CodeBlock language string ->
                    CodeBlock language string

                AttachedFile fileId ->
                    AttachedFile fileId
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


type alias LoopState =
    { current : Array String, rest : Array RichText }


parser : SeqDict (Id UserId) { a | name : PersonName } -> List Modifiers -> Parser (Array RichText)
parser users modifiers =
    Parser.loop
        { current = Array.empty, rest = Array.empty }
        (\state ->
            Parser.oneOf
                [ Parser.succeed identity
                    |. Parser.symbol "@"
                    |= Parser.oneOf
                        (List.map
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
                            (SeqDict.toList users)
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
                , Parser.succeed Tuple.pair
                    |= Parser.oneOf
                        [ Parser.symbol "http://" |> Parser.map (\_ -> Url.Http)
                        , Parser.symbol "https://" |> Parser.map (\_ -> Url.Https)
                        ]
                    |= (Parser.chompWhile (\char -> char /= ' ' && char /= '\n' && char /= '\t' && char /= '"' && char /= '<' && char /= '>' && char /= '\\' && char /= '^' && char /= '`' && char /= '{' && char /= '|' && char /= '}')
                            |> Parser.getChompedString
                       )
                    |> Parser.map
                        (\( protocol, rest ) ->
                            (case Url.fromString ("https://" ++ rest) of
                                Just _ ->
                                    { current = Array.empty
                                    , rest =
                                        Array.append
                                            state.rest
                                            (Array.push (Hyperlink protocol rest) (parserHelper state))
                                    }

                                Nothing ->
                                    { current = Array.push (hyperlinkToString protocol rest) state.current
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
                    |> Parser.andThen (\_ -> Parser.chompWhile (\char -> not (SeqSet.member char stopOnChar)))
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


attachedFilePrefix : String
attachedFilePrefix =
    "[!"


attachedFileSuffix : String
attachedFileSuffix =
    "]"


allModifiers : List Modifiers
allModifiers =
    [ IsBold
    , IsItalic
    , IsUnderlined
    , IsStrikethrough
    , IsSpoilered
    ]


stopOnChar : SeqSet Char
stopOnChar =
    [ '[', '@', 'h', '`' ]
        ++ List.map
            (\modifier -> modifierToSymbol modifier |> String.Nonempty.head)
            allModifiers
        |> SeqSet.fromList


codeBlockParser : Parser ( Language, String )
codeBlockParser =
    Parser.succeed
        (\text ->
            case String.split "\n" text of
                [ single ] ->
                    ( None, single )

                head :: rest ->
                    if String.contains " " head then
                        ( None, text )

                    else
                        case String.Nonempty.fromString head of
                            Just nonempty ->
                                ( Language nonempty, String.join "\n" rest )

                            Nothing ->
                                ( None, text )

                [] ->
                    ( None, "" )
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


bailOut : LoopState -> List Modifiers -> Step state (Array RichText)
bailOut state modifiers =
    --let
    --    _ =
    --        Debug.log "bailOut" ( modifiers, state )
    --in
    Array.append
        (case modifiers of
            IsBold :: _ ->
                Array.fromList [ NormalText '*' "" ]

            IsItalic :: _ ->
                Array.fromList [ NormalText '_' "" ]

            IsUnderlined :: _ ->
                Array.fromList [ NormalText '_' "_" ]

            IsStrikethrough :: _ ->
                Array.fromList [ NormalText '~' "~" ]

            IsSpoilered :: _ ->
                Array.fromList [ NormalText '|' "|" ]

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
    SeqDict (Id UserId) { a | name : PersonName }
    -> Bool
    -> Modifiers
    -> (Nonempty RichText -> RichText)
    -> LoopState
    -> List Modifiers
    -> Parser (Step LoopState (Array RichText))
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


parserHelper : LoopState -> Array RichText
parserHelper state =
    case state.current |> Array.toList |> String.concat |> normalTextFromString of
        Just a ->
            Array.fromList [ a ]

        Nothing ->
            Array.empty


mentionsUser : Id UserId -> Nonempty RichText -> Bool
mentionsUser userId nonempty =
    List.Nonempty.any
        (\richText ->
            case richText of
                NormalText _ _ ->
                    False

                UserMention mentionedUser ->
                    userId == mentionedUser

                Bold nonempty2 ->
                    mentionsUser userId nonempty2

                Italic nonempty2 ->
                    mentionsUser userId nonempty2

                Underline nonempty2 ->
                    mentionsUser userId nonempty2

                Strikethrough nonempty2 ->
                    mentionsUser userId nonempty2

                Spoiler nonempty2 ->
                    mentionsUser userId nonempty2

                Hyperlink _ _ ->
                    False

                InlineCode _ _ ->
                    False

                CodeBlock _ _ ->
                    False

                AttachedFile _ ->
                    False
        )
        nonempty


view :
    Int
    -> (Int -> msg)
    -> SeqSet Int
    -> SeqDict (Id UserId) { a | name : PersonName }
    -> SeqDict (Id FileId) FileData
    -> Nonempty RichText
    -> List (Html msg)
view containerWidth pressedSpoiler revealedSpoilers users attachedFiles nonempty =
    viewHelper
        (Just containerWidth)
        pressedSpoiler
        0
        { spoiler = False, underline = False, italic = False, bold = False, strikethrough = False }
        revealedSpoilers
        users
        attachedFiles
        nonempty
        |> Tuple.second


preview :
    (Int -> msg)
    -> SeqSet Int
    -> SeqDict (Id UserId) { a | name : PersonName }
    -> SeqDict (Id FileId) FileData
    -> Nonempty RichText
    -> List (Html msg)
preview pressedSpoiler revealedSpoilers users attachedFiles nonempty =
    viewHelper
        Nothing
        pressedSpoiler
        0
        { spoiler = False, underline = False, italic = False, bold = False, strikethrough = False }
        revealedSpoilers
        users
        attachedFiles
        nonempty
        |> Tuple.second


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
    Maybe Int
    -> (Int -> msg)
    -> Int
    -> RichTextState
    -> SeqSet Int
    -> SeqDict (Id UserId) { a | name : PersonName }
    -> SeqDict (Id FileId) FileData
    -> Nonempty RichText
    -> ( Int, List (Html msg) )
viewHelper containerWidth pressedSpoiler spoilerIndex state revealedSpoilers allUsers attachedFiles nonempty =
    List.foldl
        (\item ( spoilerIndex2, currentList ) ->
            case item of
                UserMention userId ->
                    ( spoilerIndex2, currentList ++ [ MyUi.userLabelHtml userId allUsers ] )

                NormalText char text ->
                    ( spoilerIndex2
                    , currentList ++ normalTextView (String.cons char text) state
                    )

                Italic nonempty2 ->
                    let
                        ( spoilerIndex3, list ) =
                            viewHelper
                                containerWidth
                                pressedSpoiler
                                spoilerIndex2
                                { state | italic = True }
                                revealedSpoilers
                                allUsers
                                attachedFiles
                                nonempty2
                    in
                    ( spoilerIndex3, currentList ++ list )

                Underline nonempty2 ->
                    let
                        ( spoilerIndex3, list ) =
                            viewHelper
                                containerWidth
                                pressedSpoiler
                                spoilerIndex2
                                { state | underline = True }
                                revealedSpoilers
                                allUsers
                                attachedFiles
                                nonempty2
                    in
                    ( spoilerIndex3, currentList ++ list )

                Bold nonempty2 ->
                    let
                        ( spoilerIndex3, list ) =
                            viewHelper
                                containerWidth
                                pressedSpoiler
                                spoilerIndex2
                                { state | bold = True }
                                revealedSpoilers
                                allUsers
                                attachedFiles
                                nonempty2
                    in
                    ( spoilerIndex3, currentList ++ list )

                Strikethrough nonempty2 ->
                    let
                        ( spoilerIndex3, list ) =
                            viewHelper
                                containerWidth
                                pressedSpoiler
                                spoilerIndex2
                                { state | strikethrough = True }
                                revealedSpoilers
                                allUsers
                                attachedFiles
                                nonempty2
                    in
                    ( spoilerIndex3, currentList ++ list )

                Spoiler nonempty2 ->
                    let
                        revealed =
                            SeqSet.member spoilerIndex2 revealedSpoilers

                        -- Ignore the spoiler index value. It shouldn't be possible to have nested spoilers
                        ( _, list ) =
                            viewHelper
                                containerWidth
                                pressedSpoiler
                                spoilerIndex2
                                (if revealed then
                                    state

                                 else
                                    { state | spoiler = True }
                                )
                                revealedSpoilers
                                allUsers
                                attachedFiles
                                nonempty2
                    in
                    ( spoilerIndex2 + 1
                    , currentList
                        ++ [ Html.span
                                ([ Html.Attributes.style "padding" "0 2px 0 2px"
                                 , Html.Attributes.style "border-radius" "2px"
                                 ]
                                    ++ (if revealed then
                                            [ Html.Attributes.style "background" "rgb(30,30,30)" ]

                                        else
                                            [ Html.Events.onClick (pressedSpoiler spoilerIndex2)
                                            , Html.Attributes.style "cursor" "pointer"
                                            , Html.Attributes.style "background" "rgb(0,0,0)"
                                            ]
                                       )
                                )
                                list
                           ]
                    )

                Hyperlink protocol rest ->
                    let
                        text : String
                        text =
                            hyperlinkToString protocol rest
                    in
                    ( spoilerIndex2
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
                                Html.a
                                    [ htmlAttrIf state.italic (Html.Attributes.style "font-style" "oblique")
                                    , htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                                    , htmlAttrIf state.bold (Html.Attributes.style "font-weight" "700")
                                    , htmlAttrIf state.strikethrough (Html.Attributes.style "text-decoration" "line-through")
                                    , Html.Attributes.href text
                                    , Html.Attributes.target "_blank"
                                    , Html.Attributes.rel "noreferrer"
                                    ]
                                    [ Html.text text ]
                           ]
                    )

                InlineCode char rest ->
                    ( spoilerIndex2
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
                    case containerWidth of
                        Just _ ->
                            ( spoilerIndex2
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

                        Nothing ->
                            ( spoilerIndex2
                            , currentList ++ [ Html.text "<...>" ]
                            )

                AttachedFile fileId ->
                    case containerWidth of
                        Just containerWidth2 ->
                            ( spoilerIndex2
                            , case SeqDict.get fileId attachedFiles of
                                Just fileData ->
                                    let
                                        fileUrl =
                                            FileStatus.fileUrl fileData.contentType fileData.fileHash
                                    in
                                    currentList
                                        ++ [ case FileStatus.contentTypeType fileData.contentType of
                                                FileStatus.Image ->
                                                    Html.a
                                                        [ Html.Attributes.href fileUrl
                                                        , Html.Attributes.target "_blank"
                                                        , Html.Attributes.rel "noreferrer"
                                                        , Html.Attributes.style "object-fit" "contain"
                                                        ]
                                                        [ case fileData.imageSize of
                                                            Just imageSize ->
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
                                                                        min 400 (toFloat w2 * aspect)

                                                                    w3 =
                                                                        h2 / aspect
                                                                in
                                                                Html.img
                                                                    [ Html.Attributes.src fileUrl
                                                                    , Html.Attributes.style "display" "block"
                                                                    , Html.Attributes.width (round w3)
                                                                    , Html.Attributes.height (round h2)

                                                                    --, Html.Attributes.style "height"
                                                                    ]
                                                                    []

                                                            Nothing ->
                                                                Html.img
                                                                    [ Html.Attributes.src fileUrl
                                                                    , Html.Attributes.style "display" "block"
                                                                    , Html.Attributes.width containerWidth2
                                                                    , Html.Attributes.style "max-width" "min(300px, 100%)"
                                                                    , Html.Attributes.style "max-height" "400px"
                                                                    ]
                                                                    []
                                                        ]

                                                _ ->
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
                                           ]

                                Nothing ->
                                    currentList ++ normalTextView (attachedFilePrefix ++ Id.toString fileId ++ attachedFileSuffix) state
                            )

                        Nothing ->
                            ( spoilerIndex2
                            , currentList ++ [ Html.text "<file>" ]
                            )
        )
        ( spoilerIndex, [] )
        (List.Nonempty.toList nonempty)


textInputView : SeqDict (Id UserId) { a | name : PersonName } -> SeqDict (Id FileId) b -> Nonempty RichText -> List (Html msg)
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
    -> SeqDict (Id UserId) { a | name : PersonName }
    -> SeqDict (Id FileId) b
    -> Nonempty RichText
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
                        :: textInputViewHelper { state | italic = True } allUsers attachedFiles nonempty2
                        ++ [ formatText "_" ]

                Underline nonempty2 ->
                    formatText "__"
                        :: textInputViewHelper { state | underline = True } allUsers attachedFiles nonempty2
                        ++ [ formatText "__" ]

                Bold nonempty2 ->
                    formatText "*"
                        :: textInputViewHelper { state | bold = True } allUsers attachedFiles nonempty2
                        ++ [ formatText "*" ]

                Strikethrough nonempty2 ->
                    formatText "~~"
                        :: textInputViewHelper { state | strikethrough = True } allUsers attachedFiles nonempty2
                        ++ [ formatText "~~" ]

                Spoiler nonempty2 ->
                    formatText "||"
                        :: textInputViewHelper { state | spoiler = True } allUsers attachedFiles nonempty2
                        ++ [ formatText "||" ]

                Hyperlink protocol rest ->
                    [ Html.span
                        [ htmlAttrIf state.italic (Html.Attributes.style "font-style" "oblique")
                        , htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                        , htmlAttrIf state.bold (Html.Attributes.style "text-shadow" "0.7px 0px 0px white")
                        , htmlAttrIf state.strikethrough (Html.Attributes.style "text-decoration" "line-through")
                        , htmlAttrIf state.spoiler (Html.Attributes.style "background-color" "rgb(0,0,0)")
                        , Html.Attributes.style "color" "rgb(66,93,203)"
                        ]
                        [ Html.text (hyperlinkToString protocol rest) ]
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

                                    None ->
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
        )
        (List.Nonempty.toList nonempty)


hyperlinkToString : Protocol -> String -> String
hyperlinkToString protocol rest =
    (case protocol of
        Http ->
            "http://"

        Https ->
            "https://"
    )
        ++ rest


formatText : String -> Html msg
formatText text =
    Html.span [ Html.Attributes.style "color" "rgb(180,180,180)" ] [ Html.text text ]


toDiscord :
    OneToOne (Discord.Id.Id Discord.Id.UserId) (Id UserId)
    -> SeqDict (Id FileId) FileData
    -> Nonempty RichText
    -> List (Discord.Markdown.Markdown a)
toDiscord mapping attachedFiles content =
    List.map
        (\item ->
            case item of
                UserMention userId ->
                    case OneToOne.first userId mapping of
                        Just discordUserId ->
                            Discord.Markdown.ping discordUserId

                        Nothing ->
                            Discord.Markdown.text "@???"

                NormalText char string ->
                    Discord.Markdown.text (String.cons char string)

                Bold nonempty ->
                    Discord.Markdown.boldMarkdown (toDiscord mapping attachedFiles nonempty)

                Italic nonempty ->
                    Discord.Markdown.italicMarkdown (toDiscord mapping attachedFiles nonempty)

                Underline nonempty ->
                    Discord.Markdown.underlineMarkdown (toDiscord mapping attachedFiles nonempty)

                Strikethrough nonempty ->
                    Discord.Markdown.strikethroughMarkdown (toDiscord mapping attachedFiles nonempty)

                Spoiler nonempty ->
                    Discord.Markdown.spoiler (toDiscord mapping attachedFiles nonempty)

                Hyperlink protocol string ->
                    Discord.Markdown.text (hyperlinkToString protocol string)

                InlineCode char string ->
                    Discord.Markdown.code (String.cons char string)

                CodeBlock language string ->
                    Discord.Markdown.codeBlock
                        (case language of
                            Language language2 ->
                                Just (String.Nonempty.toString language2)

                            None ->
                                Nothing
                        )
                        string

                AttachedFile fileId ->
                    case SeqDict.get fileId attachedFiles of
                        Just fileData ->
                            Discord.Markdown.text (FileStatus.fileUrl fileData.contentType fileData.fileHash)

                        Nothing ->
                            Discord.Markdown.text ""
        )
        (List.Nonempty.toList content)
