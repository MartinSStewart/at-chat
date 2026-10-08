port module TetrominoBot exposing (Request(..), encodeState, fromJs, noMatch, requestFailed, toJs)

{-| Lets a script in the browser play Tetromino Fort, for playtesting: it asks for the match as
JSON and sends inputs back. elm-pkg-js/tetromino-bot.js only listens when the page's URL has
`bot` in its query string, and the match is only sent when it asks.
-}

import Dict
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Subscription as Subscription exposing (Subscription)
import Id exposing (Id, UserId)
import Json.Decode exposing (Decoder)
import Json.Encode
import SeqDict
import SeqSet
import Tetromino exposing (Shape)
import TetrominoSim exposing (MatchState, NpcKind(..), Point)


port tetromino_bot_to_js : Json.Encode.Value -> Cmd msg


port tetromino_bot_from_js : (Json.Decode.Value -> msg) -> Sub msg


type Request
    = GetState Int
    | SendInput TetrominoSim.Input


fromJs : (Result String Request -> msg) -> Subscription FrontendOnly msg
fromJs msg =
    Subscription.fromJs
        "tetromino_bot_from_js"
        tetromino_bot_from_js
        (\json -> Json.Decode.decodeValue decodeRequest json |> Result.mapError Json.Decode.errorToString |> msg)


toJs : Json.Encode.Value -> Command FrontendOnly toMsg msg
toJs value =
    Command.sendToJs "tetromino_bot_to_js" tetromino_bot_to_js value


decodeRequest : Decoder Request
decodeRequest =
    Json.Decode.field "type" Json.Decode.string
        |> Json.Decode.andThen
            (\kind ->
                case kind of
                    "getState" ->
                        Json.Decode.map GetState (Json.Decode.field "id" Json.Decode.int)

                    "join" ->
                        Json.Decode.succeed (SendInput TetrominoSim.Join)

                    "move" ->
                        Json.Decode.map2
                            (\x y -> SendInput (TetrominoSim.MoveTo x y))
                            (Json.Decode.field "x" Json.Decode.int)
                            (Json.Decode.field "y" Json.Decode.int)

                    "drop" ->
                        Json.Decode.map4
                            (\x y quarterTurns upright ->
                                SendInput
                                    (TetrominoSim.Drop
                                        { x = x
                                        , y = y
                                        , orientation =
                                            Tetromino.orientation
                                                (if upright then
                                                    Tetromino.Upright

                                                 else
                                                    Tetromino.Flat
                                                )
                                                quarterTurns
                                        }
                                    )
                            )
                            (Json.Decode.field "x" Json.Decode.int)
                            (Json.Decode.field "y" Json.Decode.int)
                            (Json.Decode.field "quarterTurns" Json.Decode.int)
                            (Json.Decode.field "upright" Json.Decode.bool)

                    _ ->
                        Json.Decode.fail ("Unknown request type " ++ kind)
            )


requestFailed : String -> Json.Encode.Value
requestFailed error =
    Json.Encode.object [ ( "type", Json.Encode.string "error" ), ( "message", Json.Encode.string error ) ]


noMatch : Int -> Json.Encode.Value
noMatch id =
    Json.Encode.object [ ( "type", Json.Encode.string "noMatch" ), ( "id", Json.Encode.int id ) ]


{-| The match as `userId` sees it. Positions are in cells, z is height, and a player or NPC stands
at the middle of its cell at x + 0.5.
-}
encodeState : Int -> Id UserId -> MatchState -> Json.Encode.Value
encodeState id userId state =
    Json.Encode.object
        [ ( "type", Json.Encode.string "state" )
        , ( "id", Json.Encode.int id )
        , ( "frame", Json.Encode.int state.frame )
        , ( "framesPerSecond", Json.Encode.int TetrominoSim.framesPerSecond )
        , ( "gridSize", Json.Encode.int TetrominoSim.gridSize )
        , ( "snowballGravity", Json.Encode.float TetrominoSim.snowballGravity )
        , ( "round"
          , Json.Encode.object
                [ ( "number", Json.Encode.int state.round.number )
                , ( "startedAt", Json.Encode.int state.round.startedAt )
                , ( "nextRoundAt", maybe Json.Encode.int state.round.nextRoundAt )
                ]
          )
        , ( "me"
          , case SeqDict.get userId state.players of
                Just player ->
                    Json.Encode.object
                        [ ( "x", Json.Encode.float player.position.x )
                        , ( "y", Json.Encode.float player.position.y )
                        , ( "z", Json.Encode.float player.position.z )
                        , ( "knockedOut", Json.Encode.bool (player.knockedOutAt /= Nothing) )
                        , ( "target", maybe (\( x, y ) -> Json.Encode.list Json.Encode.int [ x, y ]) player.target )
                        , ( "piecesLeft", Json.Encode.int player.piecesLeft )
                        , ( "canDrop", Json.Encode.bool (TetrominoSim.canDrop state.frame player) )
                        , ( "nextDropAt", Json.Encode.int player.nextDropAt )
                        , ( "protectedUntil", Json.Encode.int player.protectedUntil )
                        , ( "queue"
                          , Json.Encode.list
                                (\shape -> Json.Encode.string (shapeName shape))
                                [ player.queue.current, player.queue.next, player.queue.afterNext ]
                          )
                        , ( "currentPieceOrientations", orientations player.queue.current )
                        ]

                Nothing ->
                    Json.Encode.null
          )
        , ( "waiting", Json.Encode.bool (SeqSet.member userId state.waitingPlayers) )
        , ( "players"
          , Json.Encode.list
                (\( otherId, player ) ->
                    Json.Encode.object
                        [ ( "id", Json.Encode.int (Id.toInt otherId) )
                        , ( "x", Json.Encode.float player.position.x )
                        , ( "y", Json.Encode.float player.position.y )
                        , ( "z", Json.Encode.float player.position.z )
                        , ( "knockedOut", Json.Encode.bool (player.knockedOutAt /= Nothing) )
                        ]
                )
                (SeqDict.toList state.players |> List.filter (\( otherId, _ ) -> otherId /= userId))
          )
        , ( "towers"
          , Json.Encode.list
                (\tower ->
                    Json.Encode.object
                        [ ( "x", Json.Encode.float tower.position.x )
                        , ( "y", Json.Encode.float tower.position.y )
                        , ( "z", Json.Encode.float tower.position.z )
                        , ( "npcs"
                          , Json.Encode.list
                                (\npc -> Json.Encode.string (kindName npc.kind))
                                (tower.bottom :: tower.above)
                          )
                        ]
                )
                state.towers
          )
        , ( "snowballs"
          , Json.Encode.list
                (\snowball ->
                    Json.Encode.object
                        [ ( "position", point snowball.position ), ( "velocity", point snowball.velocity ) ]
                )
                state.snowballs
          )
        , ( "pickups"
          , Json.Encode.list
                (\pickup -> Json.Encode.list Json.Encode.int [ pickup.x, pickup.y, pickup.z ])
                state.pickups
          )
        , ( "columns"
          , Dict.foldl
                (\( x, y, z ) _ tops -> Dict.update ( x, y ) (\top -> Just (max (z + 1) (Maybe.withDefault 0 top))) tops)
                Dict.empty
                state.occupied
                |> Dict.toList
                |> Json.Encode.list (\( ( x, y ), top ) -> Json.Encode.list Json.Encode.int [ x, y, top ])
          )
        ]


{-| The cells the piece covers in each way it can be dropped, relative to the cell dropped on.
-}
orientations : Shape -> Json.Encode.Value
orientations shape =
    List.concatMap
        (\( upright, stance ) ->
            List.map
                (\quarterTurns ->
                    Json.Encode.object
                        [ ( "quarterTurns", Json.Encode.int quarterTurns )
                        , ( "upright", Json.Encode.bool upright )
                        , ( "cells"
                          , Json.Encode.list
                                (\( x, y, z ) -> Json.Encode.list Json.Encode.int [ x, y, z ])
                                (Tetromino.cells (Tetromino.orientation stance quarterTurns) shape)
                          )
                        ]
                )
                (List.range 0 3)
        )
        [ ( False, Tetromino.Flat ), ( True, Tetromino.Upright ) ]
        |> Json.Encode.list identity


point : Point -> Json.Encode.Value
point { x, y, z } =
    Json.Encode.object [ ( "x", Json.Encode.float x ), ( "y", Json.Encode.float y ), ( "z", Json.Encode.float z ) ]


maybe : (a -> Json.Encode.Value) -> Maybe a -> Json.Encode.Value
maybe encode value =
    case value of
        Just a ->
            encode a

        Nothing ->
            Json.Encode.null


shapeName : Shape -> String
shapeName shape =
    case shape of
        Tetromino.I ->
            "I"

        Tetromino.O ->
            "O"

        Tetromino.T ->
            "T"

        Tetromino.S ->
            "S"

        Tetromino.Z ->
            "Z"

        Tetromino.J ->
            "J"

        Tetromino.L ->
            "L"


kindName : NpcKind -> String
kindName kind =
    case kind of
        Chaser ->
            "chaser"

        Thrower ->
            "thrower"

        Jumper ->
            "jumper"
