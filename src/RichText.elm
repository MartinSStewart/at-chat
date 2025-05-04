module RichText exposing
    ( RichText(..)
    , fromNonemptyString
    , isMentioned
    )

import Id exposing (Id, UserId)
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import Parser
import PersonName exposing (PersonName)
import SeqDict exposing (SeqDict)
import String.Nonempty exposing (NonemptyString)
import User exposing (FrontendUser)


type RichText
    = UserMention (Id UserId)
    | NormalText NonemptyString
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
--parser =
--    Parser.chompWhile (\char -> char /= '_') |> Parser.getChompedString
