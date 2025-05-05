module RichText exposing
    ( RichText(..)
    , fromNonemptyString
    , fromString
    , isMentioned
    , parser
    , toString
    )

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



--
--handleTextFormatting : List RichText -> List RichText
--handleTextFormatting richTexts =
--    0
--
--


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
            case List.Nonempty.fromList ok of
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
    List.Nonempty.foldl
        (\richText nonempty2 ->
            case ( List.Nonempty.head nonempty2, richText ) of
                ( NormalText previous, NormalText text ) ->
                    NormalText (String.Nonempty.append (String.Nonempty.toString previous) text)
        )
        (Nonempty (List.Nonempty.head nonempty))
        (List.Nonempty.tail nonempty)


type Modifiers
    = IsBold
    | IsItalic
    | IsUnderlined


type alias LoopState =
    { current : List String, rest : List RichText }


parser : List Modifiers -> String -> Parser (List RichText)
parser modifiers previousChar =
    Parser.loop
        { current = [ previousChar ], rest = [] }
        (\state ->
            Parser.oneOf
                [ if List.member IsBold modifiers then
                    Parser.map
                        (\() ->
                            case parserHelper state ++ state.rest |> List.reverse |> List.Nonempty.fromList of
                                Just nonempty ->
                                    Done [ Bold nonempty ]

                                Nothing ->
                                    Done []
                        )
                        (Parser.symbol "*")

                  else
                    Parser.succeed identity
                        |. Parser.symbol "*"
                        |= Parser.oneOf
                            [ Parser.chompIf (\char -> char /= ' ' && char /= '*')
                                |> Parser.getChompedString
                                |> Parser.andThen (parser (IsBold :: modifiers))
                                |> Parser.map
                                    (\a ->
                                        Loop
                                            { current = []
                                            , rest = a ++ parserHelper state ++ state.rest
                                            }
                                    )
                            , Loop { current = "*" :: state.current, rest = state.rest }
                                |> Parser.succeed
                            ]
                , if List.member IsItalic modifiers then
                    Parser.map
                        (\() ->
                            case parserHelper state ++ state.rest |> List.reverse |> List.Nonempty.fromList of
                                Just nonempty ->
                                    Done [ Italic nonempty ]

                                Nothing ->
                                    Done []
                        )
                        (Parser.symbol "_")

                  else
                    Parser.succeed identity
                        |. Parser.symbol "_"
                        |= Parser.oneOf
                            [ Parser.chompIf (\char -> char /= ' ' && char /= '_')
                                |> Parser.getChompedString
                                |> Parser.andThen (parser (IsItalic :: modifiers))
                                |> Parser.map
                                    (\a ->
                                        Loop
                                            { current = []
                                            , rest = a ++ parserHelper state ++ state.rest
                                            }
                                    )
                            , Loop { current = "_" :: state.current, rest = state.rest }
                                |> Parser.succeed
                            ]
                , Parser.chompIf (\_ -> True)
                    |> Parser.getChompedString
                    |> Parser.map
                        (\a ->
                            Loop
                                { current = a :: state.current
                                , rest = state.rest
                                }
                        )
                , Parser.end
                    |> Parser.map
                        (\() ->
                            Done
                                (parserHelper
                                    { state
                                        | current =
                                            (case modifiers of
                                                IsBold :: _ ->
                                                    [ "*" ]

                                                IsItalic :: _ ->
                                                    [ "_" ]

                                                IsUnderlined :: _ ->
                                                    [ "__" ]

                                                _ ->
                                                    []
                                            )
                                                ++ state.current
                                    }
                                    ++ state.rest
                                    |> List.reverse
                                )
                        )
                ]
        )


parserHelper : LoopState -> List RichText
parserHelper state =
    case
        List.reverse state.current
            |> String.concat
            |> String.Nonempty.fromString
    of
        Just nonempty ->
            [ NormalText nonempty ]

        Nothing ->
            []
