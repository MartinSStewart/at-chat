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
import Id exposing (Id, UserId)
import List.Nonempty exposing (Nonempty(..))
import MyUi
import Parser exposing ((|.), (|=), Parser, Step(..))
import PersonName exposing (PersonName)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import String.Nonempty exposing (NonemptyString(..))
import Ui exposing (Element)
import Ui.Font
import Ui.Input
import Ui.Prose
import Url exposing (Protocol(..), Url)


type RichText
    = UserMention (Id UserId)
    | NormalText Char String
    | Bold (Nonempty RichText)
    | Italic (Nonempty RichText)
    | Underline (Nonempty RichText)
    | Spoiler (Nonempty RichText)
    | Hyperlink Url.Protocol String


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
                , modifierHelper users IsBold Bold state modifiers
                , modifierHelper users IsUnderlined Underline state modifiers
                , modifierHelper users IsItalic Italic state modifiers
                , modifierHelper users IsSpoilered Spoiler state modifiers
                , Parser.succeed Tuple.pair
                    |= Parser.oneOf
                        [ Parser.symbol "http://" |> Parser.map (\_ -> Url.Http)
                        , Parser.symbol "https://" |> Parser.map (\_ -> Url.Https)
                        ]
                    |= (Parser.chompWhile (\char -> char /= ' ' && char /= '"' && char /= '<' && char /= '>' && char /= '\\' && char /= '^' && char /= '`' && char /= '{' && char /= '|' && char /= '}')
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
    -> Modifiers
    -> (Nonempty RichText -> RichText)
    -> LoopState
    -> List Modifiers
    -> Parser (Step LoopState (Array RichText))
modifierHelper users modifier container state modifiers =
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
                [ getRemainingText
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
        )
        nonempty


view :
    (Int -> msg)
    -> SeqSet Int
    -> SeqDict (Id UserId) { a | name : PersonName }
    -> Nonempty RichText
    -> List (Element msg)
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
    -> ( Int, List (Element msg) )
viewHelper pressedSpoiler spoilerIndex state revealedSpoilers allUsers nonempty =
    List.foldl
        (\item ( spoilerIndex2, list ) ->
            case item of
                UserMention userId ->
                    ( spoilerIndex2, list ++ [ MyUi.userLabel userId allUsers ] )

                NormalText char text ->
                    ( spoilerIndex2
                    , list
                        ++ [ Ui.el
                                [ Html.Attributes.style "white-space" "pre-wrap" |> Ui.htmlAttribute
                                , Ui.attrIf state.italic Ui.Font.italic
                                , Ui.attrIf state.underline Ui.Font.italic
                                , Ui.attrIf state.bold Ui.Font.bold
                                , Ui.attrIf state.spoiler (Ui.opacity 0)
                                ]
                                (Ui.text (String.cons char text))
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
                        ++ [ Ui.Prose.paragraph
                                ([ Ui.paddingXY 2 0
                                 , Ui.rounded 2
                                 ]
                                    ++ (if revealed then
                                            [ Ui.background MyUi.spoilerRevealedColor ]

                                        else
                                            [ Ui.Input.button (pressedSpoiler spoilerIndex2)
                                            , Ui.background MyUi.spoilerColor
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
                                    , htmlAttrIf state.bold (Html.Attributes.style "text-shadow" "0.7px 0px 0px white")
                                    , Html.Attributes.style "opacity" "0"
                                    ]
                                    [ Html.text text ]
                                    |> Ui.html

                             else
                                Html.a
                                    [ htmlAttrIf state.italic (Html.Attributes.style "font-style" "oblique")
                                    , htmlAttrIf state.underline (Html.Attributes.style "text-decoration" "underline")
                                    , htmlAttrIf state.bold (Html.Attributes.style "text-shadow" "0.7px 0px 0px white")
                                    , Html.Attributes.href text
                                    , Html.Attributes.target "_blank"
                                    , Html.Attributes.rel "noreferrer"
                                    ]
                                    [ Html.text text ]
                                    |> Ui.html
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
        )
        (List.Nonempty.toList nonempty)


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
