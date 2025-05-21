module RichText exposing
    ( RichText(..)
    , RichTextState
    , append
    , fromNonemptyString
    , mentionsUser
    , parser
    , textInputView
    , toString
    , view
    )

import Array exposing (Array)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Id exposing (Id, UserId)
import List.Nonempty exposing (Nonempty(..))
import MyUi
import Parser exposing ((|.), (|=), Parser, Step(..))
import PersonName exposing (PersonName)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import String.Nonempty exposing (NonemptyString(..))
import Url exposing (Protocol(..), Url)


type RichText
    = UserMention (Id UserId)
    | NormalText Char String
    | Bold (Nonempty RichText)
    | Italic (Nonempty RichText)
    | Underline (Nonempty RichText)
    | Spoiler (Nonempty RichText)
    | Hyperlink Url.Protocol String
    | InlineCode Char String


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

                Spoiler a ->
                    "||" ++ toString users a ++ "||"

                Hyperlink protocol rest ->
                    hyperlinkToString protocol rest

                InlineCode char rest ->
                    "`" ++ String.cons char rest ++ "`"
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

        Err error ->
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

                Spoiler a ->
                    List.Nonempty.cons (Spoiler (normalize a)) nonempty2

                Hyperlink protocol rest ->
                    List.Nonempty.cons (Hyperlink protocol rest) nonempty2

                InlineCode char string ->
                    List.Nonempty.cons (InlineCode char string) nonempty2
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

                Spoiler a ->
                    Spoiler (normalize a)

                Hyperlink protocol rest ->
                    Hyperlink protocol rest

                InlineCode char string ->
                    InlineCode char string
            )
            []
        )
        (List.Nonempty.tail nonempty)
        |> List.Nonempty.reverse


type Modifiers
    = IsBold
    | IsItalic
    | IsUnderlined
    | IsSpoilered


modifierToSymbol : Modifiers -> String
modifierToSymbol modifier =
    case modifier of
        IsBold ->
            "*"

        IsItalic ->
            "_"

        IsUnderlined ->
            "__"

        IsSpoilered ->
            "||"


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
                , modifierHelper users False IsSpoilered Spoiler state modifiers
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
                                Just url ->
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
                , Parser.chompIf (\_ -> True)
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


bailOut : LoopState -> List Modifiers -> Step state (Array RichText)
bailOut state modifiers =
    Array.append
        (case modifiers of
            IsBold :: _ ->
                Array.fromList [ NormalText '*' "" ]

            IsItalic :: _ ->
                Array.fromList [ NormalText '_' "" ]

            IsUnderlined :: _ ->
                Array.fromList [ NormalText '_' "_" ]

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
        symbol : String
        symbol =
            modifierToSymbol modifier
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
                        Done Array.empty
            )
            (Parser.symbol symbol)

    else if List.member modifier modifiers then
        getRemainingText
            |> Parser.andThen
                (\remainingText ->
                    if String.startsWith symbol remainingText then
                        bailOut state modifiers |> Parser.succeed

                    else
                        Parser.backtrackable (Parser.problem "")
                )

    else
        Parser.succeed identity
            |. Parser.symbol symbol
            |= Parser.oneOf
                [ if noTrailingWhitespace then
                    getRemainingText
                        |> Parser.andThen
                            (\remainingText ->
                                if
                                    String.startsWith symbol remainingText
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
                , Loop { current = Array.push symbol state.current, rest = state.rest }
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

                Spoiler nonempty2 ->
                    mentionsUser userId nonempty2

                Hyperlink _ _ ->
                    False

                InlineCode char string ->
                    False
        )
        nonempty


view :
    (Int -> msg)
    -> SeqSet Int
    -> SeqDict (Id UserId) { a | name : PersonName }
    -> Nonempty RichText
    -> List (Html msg)
view pressedSpoiler revealedSpoilers users nonempty =
    viewHelper
        pressedSpoiler
        0
        { spoiler = False, underline = False, italic = False, bold = False }
        revealedSpoilers
        users
        nonempty
        |> Tuple.second


viewHelper :
    (Int -> msg)
    -> Int
    -> RichTextState
    -> SeqSet Int
    -> SeqDict (Id UserId) { a | name : PersonName }
    -> Nonempty RichText
    -> ( Int, List (Html msg) )
viewHelper pressedSpoiler spoilerIndex state revealedSpoilers allUsers nonempty =
    List.foldl
        (\item ( spoilerIndex2, list ) ->
            case item of
                UserMention userId ->
                    ( spoilerIndex2, list ++ [ MyUi.userLabelHtml userId allUsers ] )

                NormalText char text ->
                    ( spoilerIndex2
                    , list
                        ++ [ Html.span
                                [ htmlAttrIf state.italic (Html.Attributes.style "font-style" "italic")
                                , htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                                , htmlAttrIf state.bold (Html.Attributes.style "font-weight" "700")
                                , htmlAttrIf state.spoiler (Html.Attributes.style "opacity" "0")
                                ]
                                [ Html.text (String.cons char text) ]
                           ]
                    )

                Italic nonempty2 ->
                    let
                        ( spoilerIndex3, list2 ) =
                            viewHelper
                                pressedSpoiler
                                spoilerIndex2
                                { state | italic = True }
                                revealedSpoilers
                                allUsers
                                nonempty2
                    in
                    ( spoilerIndex3, list ++ list2 )

                Underline nonempty2 ->
                    let
                        ( spoilerIndex3, list2 ) =
                            viewHelper
                                pressedSpoiler
                                spoilerIndex2
                                { state | underline = True }
                                revealedSpoilers
                                allUsers
                                nonempty2
                    in
                    ( spoilerIndex3, list ++ list2 )

                Bold nonempty2 ->
                    let
                        ( spoilerIndex3, list2 ) =
                            viewHelper
                                pressedSpoiler
                                spoilerIndex2
                                { state | bold = True }
                                revealedSpoilers
                                allUsers
                                nonempty2
                    in
                    ( spoilerIndex3, list ++ list2 )

                Spoiler nonempty2 ->
                    let
                        revealed =
                            SeqSet.member spoilerIndex2 revealedSpoilers

                        -- Ignore the spoiler index value. It shouldn't be possible to have nested spoilers
                        ( _, list2 ) =
                            viewHelper
                                pressedSpoiler
                                spoilerIndex2
                                (if revealed then
                                    state

                                 else
                                    { state | spoiler = True }
                                )
                                revealedSpoilers
                                allUsers
                                nonempty2
                    in
                    ( spoilerIndex2 + 1
                    , list
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
                                list2
                           ]
                    )

                Hyperlink protocol rest ->
                    let
                        text : String
                        text =
                            hyperlinkToString protocol rest
                    in
                    ( spoilerIndex2
                    , list
                        ++ [ if state.spoiler then
                                Html.span
                                    [ htmlAttrIf state.italic (Html.Attributes.style "font-style" "oblique")
                                    , htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                                    , htmlAttrIf state.bold (Html.Attributes.style "font-weight" "700")
                                    , Html.Attributes.style "opacity" "0"
                                    ]
                                    [ Html.text text ]

                             else
                                Html.a
                                    [ htmlAttrIf state.italic (Html.Attributes.style "font-style" "oblique")
                                    , htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                                    , htmlAttrIf state.bold (Html.Attributes.style "font-weight" "700")
                                    , Html.Attributes.href text
                                    , Html.Attributes.target "_blank"
                                    , Html.Attributes.rel "noreferrer"
                                    ]
                                    [ Html.text text ]
                           ]
                    )

                InlineCode char rest ->
                    ( spoilerIndex2
                    , list
                        ++ [ Html.span
                                [ htmlAttrIf state.italic (Html.Attributes.style "font-style" "oblique")
                                , htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                                , htmlAttrIf state.bold (Html.Attributes.style "text-shadow" "0.7px 0px 0px white")
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
        )
        ( spoilerIndex, [] )
        (List.Nonempty.toList nonempty)


textInputView : SeqDict (Id UserId) { a | name : PersonName } -> Nonempty RichText -> List (Html msg)
textInputView users nonempty =
    textInputViewHelper { underline = False, italic = False, bold = False, spoiler = False } users nonempty


htmlAttrIf : Bool -> Html.Attribute msg -> Html.Attribute msg
htmlAttrIf condition attribute =
    if condition then
        attribute

    else
        Html.Attributes.style "" ""


type alias RichTextState =
    { italic : Bool, underline : Bool, bold : Bool, spoiler : Bool }


textInputViewHelper : RichTextState -> SeqDict (Id UserId) { a | name : PersonName } -> Nonempty RichText -> List (Html msg)
textInputViewHelper state allUsers nonempty =
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
                        [ htmlAttrIf state.italic (Html.Attributes.style "font-style" "oblique")
                        , htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                        , htmlAttrIf state.bold (Html.Attributes.style "text-shadow" "0.7px 0px 0px white")
                        , htmlAttrIf state.spoiler (Html.Attributes.style "background-color" "rgb(0,0,0)")
                        ]
                        [ Html.text (String.cons char text) ]
                    ]

                Italic nonempty2 ->
                    formatText "_"
                        :: textInputViewHelper { state | italic = True } allUsers nonempty2
                        ++ [ formatText "_" ]

                Underline nonempty2 ->
                    formatText "__"
                        :: textInputViewHelper { state | underline = True } allUsers nonempty2
                        ++ [ formatText "__" ]

                Bold nonempty2 ->
                    formatText "*"
                        :: textInputViewHelper { state | bold = True } allUsers nonempty2
                        ++ [ formatText "*" ]

                Spoiler nonempty2 ->
                    formatText "||"
                        :: textInputViewHelper { state | spoiler = True } allUsers nonempty2
                        ++ [ formatText "||" ]

                Hyperlink protocol rest ->
                    [ Html.span
                        [ htmlAttrIf state.italic (Html.Attributes.style "font-style" "oblique")
                        , htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                        , htmlAttrIf state.bold (Html.Attributes.style "text-shadow" "0.7px 0px 0px white")
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
                        , if state.spoiler then
                            Html.Attributes.style "background-color" "rgb(0,0,0)"

                          else
                            Html.Attributes.style "background-color" "rgb(90,100,120)"
                        ]
                        [ Html.text (String.cons char rest) ]
                    , formatText "`"
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
