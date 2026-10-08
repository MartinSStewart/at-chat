module E2ETetromino exposing (tests)

import Array
import Audio
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Game
import Id exposing (ChannelMessageId, Id)
import Json.Encode
import SeqDict
import Test.Html.Query
import Test.Html.Selector
import TetrominoGame
import TetrominoSim
import Types exposing (BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)


tests :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
tests normalConfig =
    T.testGroup
        "Tetromino Fort"
        [ twoPlayerMatchTest normalConfig ]


mouseEvent : Int -> ( Float, Float ) -> Json.Encode.Value
mouseEvent button ( x, y ) =
    Json.Encode.object
        [ ( "timeStamp", Json.Encode.float 0 )
        , ( "button", Json.Encode.int button )
        , ( "offsetX", Json.Encode.float x )
        , ( "offsetY", Json.Encode.float y )
        ]


{-| The inputs of every tetromino match the backend knows about, oldest first.
-}
matchInputs : E2EHelper.BackendModel2 -> List ( Id ChannelMessageId, List TetrominoSim.Input )
matchInputs backend =
    SeqDict.values (E2EHelper.unwrapBackend backend).dmChannels
        |> List.concatMap (\dmChannel -> SeqDict.toList dmChannel.games)
        |> List.filterMap
            (\( matchId, gameData ) ->
                case gameData of
                    Game.GameData_TetrominoGame _ actions ->
                        Just ( matchId, List.map .input (Array.toList actions) )

                    _ ->
                        Nothing
            )


twoPlayerMatchTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
twoPlayerMatchTest normalConfig =
    E2EHelper.startTest
        "Two players join a Tetromino Fort match and both see each other's pieces"
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.tallDesktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , E2EHelper.inviteUser
                    admin
                    (\user ->
                        [ E2EHelper.openDm user 1000 "0"
                        , admin.click 100 (Dom.id "guild_openChannel_0")
                        , E2EHelper.openDm admin 100 "2"
                        , admin.click 100 (Dom.id "guild_openGamesTab")
                        , admin.click 100 (Dom.id "game_select_Tetromino Fort")
                        , admin.click 100 (Dom.id "tetrominoGame_start")
                        , admin.click 100 (Dom.id "tetrominoGame_join")
                        , user.click 100 (Dom.id "guild_gameStartedCard_0")
                        , user.click 100 (Dom.id "tetrominoGame_join")

                        -- Both players are in the match, so both show their health instead of the
                        -- join button.
                        , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "tetrominoGame_join" ])
                        , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "tetrominoGame_join" ])

                        -- Clicking the board walks the player there, right clicking drops the piece
                        -- that the spinner has stopped on.
                        , admin.custom 100 TetrominoGame.canvasId "mousedown" (mouseEvent 0 ( 300, 300 ))
                        , admin.custom 2000 TetrominoGame.canvasId "mousedown" (mouseEvent 2 ( 420, 320 ))
                        , T.checkState 2000 (matchStatesAgree admin user)
                        , T.checkBackend 100
                            (\backend ->
                                case matchInputs backend of
                                    [ ( _, inputs ) ] ->
                                        if List.any isDrop inputs && List.any isMoveTo inputs then
                                            Ok ()

                                        else
                                            Err "Expected the backend to have both a move and a drop"

                                    matches ->
                                        Err ("Expected one match, got " ++ String.fromInt (List.length matches))
                            )
                        ]
                    )
                ]
            )
        ]


{-| Both clients run the same simulation over the same inputs, so once they have both heard
about everything they have to agree down to the last snowball. They show the match a few frames
apart, since each makes its own guess at how far ahead the server's clock is, so the comparison
is of the newest frame they have both simulated.
-}
matchStatesAgree :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.Data FrontendModel E2EHelper.BackendModel2
    -> Result String ()
matchStatesAgree admin user data =
    case matchInputs data.backend of
        [ ( matchId, _ ) ] ->
            case ( clientGames admin matchId data, clientGames user matchId data ) of
                ( Just adminGame, Just userGame ) ->
                    let
                        frame : Int
                        frame =
                            min
                                (Game.tetrominoMatchState matchId adminGame |> Maybe.map .frame |> Maybe.withDefault 0)
                                (Game.tetrominoMatchState matchId userGame |> Maybe.map .frame |> Maybe.withDefault 0)
                    in
                    case
                        ( Game.tetrominoMatchStateAt frame matchId adminGame
                        , Game.tetrominoMatchStateAt frame matchId userGame
                        )
                    of
                        ( Just adminState, Just userState ) ->
                            if adminState == userState then
                                Ok ()

                            else
                                Err
                                    ("The two clients disagree about frame "
                                        ++ String.fromInt frame
                                        ++ " of the match"
                                    )

                        _ ->
                            Err ("Expected both clients to have simulated frame " ++ String.fromInt frame)

                _ ->
                    Err "Expected both clients to be showing the match"

        matches ->
            Err ("Expected one match, got " ++ String.fromInt (List.length matches))


clientGames :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> Id ChannelMessageId
    -> T.Data FrontendModel E2EHelper.BackendModel2
    -> Maybe Game.Model
clientGames client matchId data =
    case SeqDict.get client.clientId data.frontends |> Maybe.map Audio.userModel of
        Just (Types.Loaded loaded) ->
            case loaded.loginStatus of
                Types.LoggedIn loggedIn ->
                    SeqDict.values loggedIn.games
                        |> List.filter (\games -> Game.tetrominoMatchState matchId games /= Nothing)
                        |> List.head

                Types.NotLoggedIn _ ->
                    Nothing

        _ ->
            Nothing


isDrop : TetrominoSim.Input -> Bool
isDrop input =
    case input of
        TetrominoSim.Drop _ ->
            True

        TetrominoSim.Join ->
            False

        TetrominoSim.MoveTo _ _ ->
            False

        TetrominoSim.StopCycling ->
            False


isMoveTo : TetrominoSim.Input -> Bool
isMoveTo input =
    case input of
        TetrominoSim.MoveTo _ _ ->
            True

        TetrominoSim.Join ->
            False

        TetrominoSim.Drop _ ->
            False

        TetrominoSim.StopCycling ->
            False
