module RichText exposing
    ( RichText(..)
    , fromNonemptyString
    , fromString
    , isMentioned
    , parser
    , toString
    )

import Array exposing (Array)
import Id exposing (Id, UserId)
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import Parser exposing ((|.), (|=), Parser, Step(..))
import PersonName exposing (PersonName)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import String.Nonempty exposing (NonemptyString(..))
import User exposing (FrontendUser)


type RichText
    = UserMention (Id UserId)
    | NormalText NonemptyString
    | Bold (Nonempty RichText)
    | Italic (Nonempty RichText)
    | Underline (Nonempty RichText)


isMentioned : Id UserId -> Nonempty RichText -> Bool
isMentioned userId richText =
    List.any
        (\part ->
            case part of
                UserMention a ->
                    a == userId

                _ ->
                    False
        )
        (List.Nonempty.toList richText)


fromNonemptyString : SeqDict (Id UserId) FrontendUser -> NonemptyString -> Nonempty RichText
fromNonemptyString users input =
    let
        userNames : List ( Id UserId, String )
        userNames =
            SeqDict.toList users |> List.map (\( userId, user ) -> ( userId, PersonName.toString user.name ))

        segments : List { highlight : Maybe (Id UserId), rest : String }
        segments =
            List.foldl
                (\part ( isFirst, index, highlights ) ->
                    case
                        ( isFirst
                        , List.filter (\( _, name ) -> String.startsWith name part) userNames
                            |> List.Extra.maximumBy (\( _, name ) -> String.length name)
                        )
                    of
                        ( False, Just ( userId, match ) ) ->
                            ( False
                            , index + 1 + String.length part
                            , { highlight = Just userId
                              , rest = String.dropLeft (String.length match) part
                              }
                                :: highlights
                            )

                        ( False, Nothing ) ->
                            ( False
                            , index + 1 + String.length part
                            , { highlight = Nothing, rest = "@" ++ part } :: highlights
                            )

                        ( True, _ ) ->
                            ( False, index + String.length part, { highlight = Nothing, rest = part } :: highlights )
                )
                ( True, 0, [] )
                (String.split "@" (String.Nonempty.toString input))
                |> (\( _, _, chars ) -> List.reverse chars)
    in
    List.concatMap
        (\segment ->
            (case segment.highlight of
                Just userId ->
                    [ UserMention userId ]

                Nothing ->
                    []
            )
                ++ (case String.Nonempty.fromString segment.rest of
                        Just nonempty ->
                            [ NormalText nonempty ]

                        Nothing ->
                            []
                   )
        )
        segments
        --|> handleTextFormatting
        |> List.Nonempty.fromList
        |> Maybe.withDefault (Nonempty (NormalText input) [])


toString : SeqDict (Id UserId) { a | name : PersonName } -> Nonempty RichText -> String
toString users nonempty =
    List.Nonempty.map
        (\richText ->
            case richText of
                NormalText a ->
                    String.Nonempty.toString a

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
        )
        nonempty
        |> List.Nonempty.toList
        |> String.concat


fromString : NonemptyString -> Nonempty RichText
fromString string =
    case Parser.run (parser [] "") (String.Nonempty.toString string) of
        Ok ok ->
            case List.Nonempty.fromList (Array.toList ok) of
                Just nonempty ->
                    normalize nonempty

                Nothing ->
                    Nonempty (NormalText string) []

        Err error ->
            let
                _ =
                    Debug.log "error" error
            in
            Nonempty (NormalText string) []


normalize : Nonempty RichText -> Nonempty RichText
normalize nonempty =
    List.foldl
        (\richText nonempty2 ->
            case ( List.Nonempty.head nonempty2, richText ) of
                ( NormalText previous, NormalText text ) ->
                    List.Nonempty.replaceHead
                        (NormalText (String.Nonempty.append (String.Nonempty.toString previous) text))
                        nonempty2

                _ ->
                    List.Nonempty.cons richText nonempty2
        )
        (Nonempty (List.Nonempty.head nonempty) [])
        (List.Nonempty.tail nonempty)
        |> List.Nonempty.reverse


type Modifiers
    = IsBold
    | IsItalic
    | IsUnderlined


type alias LoopState =
    { current : Array String, rest : Array RichText }


parser : List Modifiers -> String -> Parser (Array RichText)
parser modifiers previousChar =
    Parser.loop
        { current = Array.fromList [ previousChar ], rest = Array.empty }
        (\state ->
            Parser.oneOf
                [ modifierHelper IsBold "*" Bold state modifiers
                , modifierHelper IsItalic "_" Italic state modifiers
                , Parser.chompIf (\_ -> True)
                    |> Parser.getChompedString
                    |> Parser.map
                        (\a ->
                            Loop
                                { current = Array.push a state.current
                                , rest = state.rest
                                }
                        )
                , Parser.map
                    (\() ->
                        Array.append
                            (case modifiers of
                                IsBold :: _ ->
                                    Array.fromList [ NormalText (NonemptyString '*' "") ]

                                IsItalic :: _ ->
                                    Array.fromList [ NormalText (NonemptyString '_' "") ]

                                IsUnderlined :: _ ->
                                    Array.fromList [ NormalText (NonemptyString '_' "_") ]

                                _ ->
                                    Array.empty
                            )
                            (Array.append state.rest (parserHelper state))
                            |> Done
                    )
                    Parser.end
                ]
        )


modifierHelper :
    Modifiers
    -> String
    -> (Nonempty RichText -> a)
    -> LoopState
    -> List Modifiers
    -> Parser (Step { current : Array String, rest : Array RichText } (Array a))
modifierHelper modifier symbol container state modifiers =
    if List.member modifier modifiers then
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

    else
        Parser.succeed identity
            |. Parser.symbol symbol
            |= Parser.oneOf
                [ Parser.chompIf (\char -> char /= ' ' && String.fromChar char /= symbol)
                    |> Parser.getChompedString
                    |> Parser.andThen (parser (modifier :: modifiers))
                    |> Parser.map
                        (\a ->
                            Loop
                                { current = Array.empty
                                , rest = Array.append state.rest (Array.append (parserHelper state) a)
                                }
                        )
                , Loop { current = Array.push symbol state.current, rest = state.rest }
                    |> Parser.succeed
                ]


parserHelper : LoopState -> Array RichText
parserHelper state =
    case
        state.current
            |> Array.toList
            |> String.concat
            |> String.Nonempty.fromString
    of
        Just nonempty ->
            Array.fromList [ NormalText nonempty ]

        Nothing ->
            Array.empty
