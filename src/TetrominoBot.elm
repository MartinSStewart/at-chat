module TetrominoBot exposing (Request, decodeRequest, encodeState, noMatch, waitingForState)

{-| The JSON the dev-only `tetromino-bot` RPC endpoint speaks, so a script can play Tetromino Fort
for playtesting without a browser.
-}

import Dict
import DmChannelId exposing (GuildOrFullDmId(..))
import Id exposing (ChannelMessageId, Id, UserId)
import Json.Decode exposing (Decoder)
import Json.Encode
import SeqDict
import SeqSet
import Tetromino exposing (Shape)
import TetrominoSim exposing (MatchState, NpcKind(..), Point)


{-| The player `userId` sends `inputs` to a match, and gets the latest state back.
-}
type alias Request =
    { userId : Id UserId
    , match : ( GuildOrFullDmId, Id ChannelMessageId )
    , inputs : List TetrominoSim.Input
    }


decodeRequest : Decoder Request
decodeRequest =
    Json.Decode.map3 Request
        (Json.Decode.field "userId" decodeId)
        (Json.Decode.map2 Tuple.pair
            (Json.Decode.oneOf
                [ Json.Decode.map2 GuildOrFullDmId_Guild
                    (Json.Decode.field "guildId" decodeId)
                    (Json.Decode.field "channelId" decodeId)
                , Json.Decode.field "dmChannelId" Json.Decode.string
                    |> Json.Decode.andThen
                        (\text ->
                            case DmChannelId.fromString text of
                                Ok dmChannelId ->
                                    Json.Decode.succeed (GuildOrFullDmId_Dm dmChannelId)

                                Err _ ->
                                    Json.Decode.fail ("Invalid DM channel " ++ text)
                        )
                ]
            )
            (Json.Decode.field "matchId" decodeId)
        )
        (Json.Decode.field "inputs" (Json.Decode.list decodeInput))


decodeId : Decoder (Id a)
decodeId =
    Json.Decode.map Id.fromInt Json.Decode.int


decodeInput : Decoder TetrominoSim.Input
decodeInput =
    Json.Decode.field "type" Json.Decode.string
        |> Json.Decode.andThen
            (\kind ->
                case kind of
                    "join" ->
                        Json.Decode.succeed TetrominoSim.Join

                    "leave" ->
                        Json.Decode.succeed TetrominoSim.Leave

                    "move" ->
                        Json.Decode.map2
                            TetrominoSim.MoveTo
                            (Json.Decode.field "x" Json.Decode.int)
                            (Json.Decode.field "y" Json.Decode.int)

                    "drop" ->
                        Json.Decode.map4
                            (\x y quarterTurns upright ->
                                TetrominoSim.Drop
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
                            (Json.Decode.field "x" Json.Decode.int)
                            (Json.Decode.field "y" Json.Decode.int)
                            (Json.Decode.field "quarterTurns" Json.Decode.int)
                            (Json.Decode.field "upright" Json.Decode.bool)

                    _ ->
                        Json.Decode.fail ("Unknown input type " ++ kind)
            )


{-| Nobody has the match open, so there is nothing to play.
-}
noMatch : Json.Encode.Value
noMatch =
    Json.Encode.object [ ( "type", Json.Encode.string "noMatch" ) ]


{-| Someone has the match open, but hasn't sent its state yet.
-}
waitingForState : Json.Encode.Value
waitingForState =
    Json.Encode.object [ ( "type", Json.Encode.string "waitingForState" ) ]


{-| The match as `userId` sees it. Positions are in cells, z is height, and a player or NPC stands
at the middle of its cell at x + 0.5.
-}
encodeState : Id UserId -> MatchState -> Json.Encode.Value
encodeState userId state =
    Json.Encode.object
        [ ( "type", Json.Encode.string "state" )
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
        , ( "crystal"
          , Json.Encode.object
                [ ( "x", Json.Encode.float TetrominoSim.crystalCenter.x )
                , ( "y", Json.Encode.float TetrominoSim.crystalCenter.y )
                , ( "health", Json.Encode.int state.crystal.health )
                , ( "gameOver", Json.Encode.bool (TetrominoSim.isGameOver state) )
                ]
          )
        , ( "giants", Json.Encode.list (\giant -> point giant.position) state.giants )
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
