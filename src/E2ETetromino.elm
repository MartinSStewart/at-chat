module E2ETetromino exposing (tests)

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


twoPlayerMatchTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
twoPlayerMatchTest normalConfig =
    E2EHelper.startTest
        "Someone opening a match gets it from the other player, and it ends when everyone leaves"
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

                        -- The user gets the match from the admin, the only one who has it.
                        , user.click 100 (Dom.id "guild_gameStartedCard_0")
                        , user.click 100 (Dom.id "tetrominoGame_join")
                        , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "tetrominoGame_join" ])
                        , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "tetrominoGame_join" ])

                        -- Early in the round, before any NPCs show up, the admin walks somewhere,
                        -- stops the spinner and drops whatever piece it landed on.
                        , admin.custom 5000 TetrominoGame.canvasId "mousedown" (mouseEvent 0 ( 300, 300 ))
                        , admin.update 100 (Audio.userMsg (Types.KeyDown { ctrlKey = False, metaKey = False, shiftKey = False, key = " " }))
                        , admin.custom 300 TetrominoGame.canvasId "mousedown" (mouseEvent 2 ( 420, 320 ))
                        , T.checkState
                            1500
                            (matchStatesAgree
                                admin
                                user
                                (\state ->
                                    if SeqDict.size state.players == 2 && List.map .status (SeqDict.values state.pieces) == [ TetrominoSim.Settled ] then
                                        Ok ()

                                    else
                                        Err "Expected both players to be in the round and the admin's piece to have landed"
                                )
                            )

                        -- Closing the match takes the user's player out of it.
                        , user.click 100 (Dom.id "guild_openGamesTab")
                        , T.checkState
                            1000
                            (\data ->
                                case clientGames admin data |> Maybe.andThen (Game.tetrominoMatchState matchId) of
                                    Just state ->
                                        if SeqDict.size state.players == 1 then
                                            Ok ()

                                        else
                                            Err "Expected the user to have left the match"

                                    Nothing ->
                                        Err "Expected the admin to still have the match"
                            )

                        -- With the admin gone too nobody has the match any more, so it's over.
                        , admin.click 100 (Dom.id "guild_openGamesTab")
                        , user.click 1000 (Dom.id "guild_gameStartedCard_0")
                        , user.checkView 1000 (Test.Html.Query.has [ Test.Html.Selector.id "tetrominoGame_over" ])
                        ]
                    )
                ]
            )
        ]


matchId : Id ChannelMessageId
matchId =
    Id.fromInt 0


{-| Both clients run the same simulation over the same inputs, so once they have both heard
about everything they have to agree down to the last snowball. They show the match a few frames
apart, since each makes its own guess at how far ahead the server's clock is, so the comparison
is of the newest frame they have both simulated.
-}
matchStatesAgree :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> (TetrominoSim.MatchState -> Result String ())
    -> T.Data FrontendModel E2EHelper.BackendModel2
    -> Result String ()
matchStatesAgree admin user checkState data =
    case ( clientGames admin data, clientGames user data ) of
        ( Just adminGame, Just userGame ) ->
            case ( Game.tetrominoMatchState matchId adminGame, Game.tetrominoMatchState matchId userGame ) of
                ( Just adminLatest, Just userLatest ) ->
                    let
                        frame : Int
                        frame =
                            min adminLatest.frame userLatest.frame
                    in
                    case
                        ( Game.tetrominoMatchStateAt frame matchId adminGame
                        , Game.tetrominoMatchStateAt frame matchId userGame
                        )
                    of
                        ( Just adminState, Just userState ) ->
                            if adminState == userState then
                                checkState adminState

                            else
                                Err
                                    ("The two clients disagree about frame "
                                        ++ String.fromInt frame
                                        ++ " of the match"
                                    )

                        _ ->
                            Err ("Expected both clients to have simulated frame " ++ String.fromInt frame)

                _ ->
                    Err "Expected both clients to have the match"

        _ ->
            Err "Expected both clients to be showing the match"


clientGames :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.Data FrontendModel E2EHelper.BackendModel2
    -> Maybe Game.Model
clientGames client data =
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
