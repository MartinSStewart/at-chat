module E2EVoiceChat exposing (voiceChatTest)

import Call
import Codec
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Lamdera as Lamdera
import Effect.Test as T exposing (PortToJs)
import Expect
import Json.Encode
import List.Extra
import LocalState exposing (CallStatus(..))
import NonemptyDict
import RPC
import SeqDict
import Test.Html.Query
import Test.Html.Selector
import Types exposing (BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)
import Url


isWebsocketRequest : PortToJs -> Maybe { clientId : Lamdera.ClientId, roomId : String }
isWebsocketRequest request =
    if request.portName == "voice_chat_to_js" then
        case Codec.decodeValue Call.voiceChatToJsCodec request.value of
            Ok (Call.ToJs_StartCall ok) ->
                case String.split "/" ok.websocketUrl of
                    [ "ws", "", "localhost", "8000", "files", "websocket", roomId, query ] ->
                        case String.split "=" query of
                            [ "?clientId", clientId ] ->
                                case Url.percentDecode clientId of
                                    Just clientId2 ->
                                        { clientId =
                                            Lamdera.clientIdFromString clientId2
                                        , roomId = roomId
                                        }
                                            |> Just

                                    Nothing ->
                                        Nothing

                            _ ->
                                Nothing

                    _ ->
                        Nothing

            _ ->
                Nothing

    else
        Nothing


startCall :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
startCall admin =
    T.group
        [ admin.click 100 (Dom.id "guild_startVoiceChat")
        , T.andThen
            100
            (\data ->
                case List.Extra.findMap isWebsocketRequest data.portRequests of
                    Just data2 ->
                        case SeqDict.get E2EHelper.sessionId0 (E2EHelper.unwrapBackend data.backend).sessions of
                            Just session ->
                                case RPC.roomIdFromString session.userId data2.roomId of
                                    Just roomId ->
                                        [ T.backendUpdate
                                            0
                                            (Types.Rpc_UserJoinedCall
                                                data.time
                                                E2EHelper.sessionId0
                                                data2.clientId
                                                session.userId
                                                roomId
                                            )
                                        ]

                                    Nothing ->
                                        [ T.checkBackend
                                            0
                                            (\_ -> Err "Rust server websocket connection attempt was made but the roomId is invalid.")
                                        ]

                            Nothing ->
                                [ T.checkBackend
                                    0
                                    (\_ -> Err "Rust server websocket connection attempt was made but it was to the wrong session.")
                                ]

                    Nothing ->
                        [ T.checkBackend 0 (\_ -> Err "No Rust server websocket connection attempt made")
                        ]
            )
        ]


voiceChatTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
voiceChatTest normalConfig =
    T.testGroup
        "Voice chat"
        [ E2EHelper.dmCallTest False normalConfig
        , E2EHelper.dmCallTest True normalConfig
        , E2EHelper.startTest
            "Hop between voice calls"
            E2EHelper.startTime
            normalConfig
            [ E2EHelper.connectTwoUsersAndJoinNewGuild
                E2EHelper.desktopWindow
                (\admin user ->
                    [ E2EHelper.openDm admin 100 "0"
                    , E2EHelper.openDm user 100 "0"
                    , admin.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.text "started a call" ])
                    , admin.click 100 (Dom.id "guild_voiceChat")
                    , startCall admin
                    , E2EHelper.tallSnapshot admin 100 { name = "Started a DM call with self" }
                    , admin.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.text "started a call" ])
                    , admin.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.text "Call ended" ])
                    , E2EHelper.tallSnapshot admin 100 { name = "Ended a DM call with self" }

                    -- Three steps back to the channel each time: the voice chat tab, the
                    -- DM, and opening the member column the DM was opened from.
                    , admin.navigateBack 100
                    , admin.navigateBack 100
                    , admin.navigateBack 100
                    , E2EHelper.openDm admin 100 "2"
                    , user.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.text "started a call" ])
                    , admin.click 100 (Dom.id "guild_voiceChat")
                    , startCall admin
                    , user.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.text "started a call" ])
                    , user.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.text "Call ended" ])
                    , admin.navigateBack 100
                    , admin.navigateBack 100
                    , admin.navigateBack 100
                    , E2EHelper.openDm admin 100 "0"
                    , admin.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.text "started a call", Test.Html.Selector.text "Call ended" ])
                    , admin.click 100 (Dom.id "guild_voiceChat")
                    , startCall admin
                    , user.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.text "started a call", Test.Html.Selector.text "Call ended" ])
                    ]
                )
            ]
        ]


dmCallTest :
    Bool
    -> T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
dmCallTest isMobile normalConfig =
    let
        -- A narrow window renders the mobile layout (touch events), a wide one
        -- the desktop layout (pointer events). See MyUi.isMobile.
        window : { width : Int, height : Int }
        window =
            if isMobile then
                iphone14Window

            else
                desktopWindow
    in
    startTest
        ("DM voice chat with another user, both on "
            ++ (if isMobile then
                    "mobile"

                else
                    "desktop"
               )
        )
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            window
            (\admin user ->
                let
                    -- Used to drag the call thumbnail.
                    touchEvent : ( Float, Float ) -> Json.Encode.Value
                    touchEvent ( x, y ) =
                        if isMobile then
                            Json.Encode.object
                                [ ( "timeStamp", Json.Encode.float 0 )
                                , ( "touches"
                                  , Json.Encode.object
                                        [ ( "length", Json.Encode.int 1 )
                                        , ( String.fromInt 0
                                          , Json.Encode.object
                                                [ ( "identifier", Json.Encode.int 0 )
                                                , ( "clientX", Json.Encode.float x )
                                                , ( "clientY", Json.Encode.float y )
                                                , ( "target"
                                                  , Json.Encode.object [ ( "id", Json.Encode.string "elm-ui-root-id" ) ]
                                                  )
                                                ]
                                          )
                                        ]
                                  )
                                ]

                        else
                            Json.Encode.object
                                [ ( "timeStamp", Json.Encode.float 0 )
                                , ( "pointerId", Json.Encode.int 0 )
                                , ( "clientX", Json.Encode.float x )
                                , ( "clientY", Json.Encode.float y )
                                ]

                    -- Mobile listens for touch events, desktop for pointer events.
                    ( startEventName, moveEventName, endEventName ) =
                        if isMobile then
                            ( "touchstart", "touchmove", "touchend" )

                        else
                            ( "pointerdown", "pointermove", "pointerup" )

                    touchEndEvent : Json.Encode.Value
                    touchEndEvent =
                        Json.Encode.object [ ( "timeStamp", Json.Encode.float 0 ) ]

                    -- The minimized call thumbnail starts in the top-right corner
                    -- (normalized position (1, 0.1)). It can travel across
                    -- windowWidth - thumbnailWidth pixels horizontally, so a drag of
                    -- dragDistanceX pixels to the left moves the normalized x by
                    -- -dragDistanceX / (windowWidth - thumbnailWidth).
                    thumbnailWidth : Float
                    thumbnailWidth =
                        if isMobile then
                            200

                        else
                            300

                    availableWidth : Float
                    availableWidth =
                        toFloat window.width - thumbnailWidth

                    dragDistanceX : Float
                    dragDistanceX =
                        150

                    -- Start the drag inside the thumbnail (its right portion) and
                    -- move dragDistanceX pixels to the left.
                    dragStart : ( Float, Float )
                    dragStart =
                        ( toFloat window.width - 150, 100 )

                    dragEnd : ( Float, Float )
                    dragEnd =
                        ( toFloat window.width - 150 - dragDistanceX, 100 )

                    expectedThumbnailX : Float
                    expectedThumbnailX =
                        clamp 0 1 (1 - dragDistanceX / availableWidth)
                in
                [ T.collapsableGroup
                    "Voice chat"
                    [ E2EHelper.openDm admin 100 "2"
                    , E2EHelper.openDm user 100 "0"
                    , admin.click 100 (Dom.id "guild_voiceChat")
                    , T.checkState 100 (checkVoiceChatFromJsEvents fromJsAfterAdminOpensVoiceChat)
                    , user.click 100 (Dom.id "guild_voiceChat")
                    , T.checkState 100 (checkVoiceChatFromJsEvents fromJsAfterUserOpensVoiceChat)
                    , admin.click 100 (Dom.id "guild_startVoiceChat")
                    , E2EHelper.tallSnapshot admin 100 { name = "Started a DM call" }
                    , T.checkBackend 200
                        (\m ->
                            case
                                List.concatMap
                                    (\( _, conns ) ->
                                        List.filter
                                            (\( _, c ) ->
                                                case c.call of
                                                    ConnectedToCall _ ->
                                                        True

                                                    NotInCall ->
                                                        False
                                            )
                                            (NonemptyDict.toList conns)
                                    )
                                    (SeqDict.toList (E2EHelper.unwrapBackend m).connections)
                            of
                                [ _ ] ->
                                    Ok ()

                                other ->
                                    Err
                                        ("Expected exactly one ConnectedToCall after admin publishes, got "
                                            ++ String.fromInt (List.length other)
                                        )
                        )
                    , T.checkState 100 (checkVoiceChatFromJsEvents fromJsAfterAdminPublishes)
                    , user.click 100 (Dom.id "guild_startVoiceChat")
                    , admin.checkView
                        50
                        (\html ->
                            Test.Html.Query.findAll [ Test.Html.Selector.exactText "started a call" ] html
                                |> Test.Html.Query.count (Expect.equal 1)
                        )
                    , T.checkBackend 150
                        (\m ->
                            case
                                List.concatMap
                                    (\( _, conns ) ->
                                        List.filter
                                            (\( _, c ) ->
                                                case c.call of
                                                    ConnectedToCall _ ->
                                                        True

                                                    NotInCall ->
                                                        False
                                            )
                                            (NonemptyDict.toList conns)
                                    )
                                    (SeqDict.toList (E2EHelper.unwrapBackend m).connections)
                            of
                                [ _, _ ] ->
                                    Ok ()

                                other ->
                                    Err
                                        ("Expected two connections with callSfu after bob publishes, got "
                                            ++ String.fromInt (List.length other)
                                        )
                        )
                    , T.checkState 100 (checkVoiceChatFromJsEvents fromJsAfterUserPublishes)
                    , E2EHelper.tallSnapshot user 100 { name = "Joined a DM call" }
                    , T.checkBackend 500
                        (\m ->
                            case
                                List.concatMap
                                    (\( _, conns ) ->
                                        List.filter
                                            (\( _, c ) ->
                                                case c.call of
                                                    ConnectedToCall _ ->
                                                        True

                                                    NotInCall ->
                                                        False
                                            )
                                            (NonemptyDict.toList conns)
                                    )
                                    (SeqDict.toList (unwrapBackend m).connections)
                            of
                                [ _, _ ] ->
                                    Ok ()

                                other ->
                                    Err
                                        ("Expected two connections with callSfu at end, got "
                                            ++ String.fromInt (List.length other)
                                        )
                        )
                    , T.checkState 100 (checkVoiceChatFromJsEvents fromJsAfterPullsComplete)
                    , user.click 100 (Dom.id "guild_voiceChat")
                    , tallSnapshot user 100 { name = "Voice chat with tab closed" }

                    -- The minimized call thumbnail can be dragged by touch
                    -- (mobile) or pointer (desktop). Grab it in the top-right
                    -- corner and drag it to the left; the normalized x should
                    -- shift accordingly while y stays at 0.1.
                    , user.custom 100 (Dom.id "elm-ui-root-id") startEventName (touchEvent dragStart)
                    , user.custom 100 (Dom.id "elm-ui-root-id") moveEventName (touchEvent dragEnd)
                    , user.custom 100 (Dom.id "elm-ui-root-id") endEventName touchEndEvent
                    , T.checkState
                        100
                        (\data ->
                            case SeqDict.get user.clientId data.frontends |> Maybe.map Audio.userModel of
                                Just (Types.Loaded loaded) ->
                                    case loaded.loginStatus of
                                        Types.LoggedIn loggedIn ->
                                            let
                                                ( x, y ) =
                                                    loggedIn.voiceChat.thumbnailPosition
                                            in
                                            if (abs (x - expectedThumbnailX) < 0.001) && (abs (y - 0.1) < 0.001) then
                                                Ok ()

                                            else
                                                Err
                                                    ("Dragging the call thumbnail should have moved it to ("
                                                        ++ String.fromFloat expectedThumbnailX
                                                        ++ ", 0.1) but got ("
                                                        ++ String.fromFloat x
                                                        ++ ", "
                                                        ++ String.fromFloat y
                                                        ++ ")"
                                                    )

                                        Types.NotLoggedIn _ ->
                                            Err "Expected user to be logged in"

                                _ ->
                                    Err "Expected user frontend to be loaded"
                        )
                    , admin.click 100 (Dom.id "guild_leaveVoiceChat")
                    , E2EHelper.tallSnapshot admin 100 { name = "Left a DM call admin perspective" }
                    , E2EHelper.tallSnapshot user 100 { name = "Left a DM call user perspective" }
                    , user.custom 100 (Dom.id "call_videoThumbnail") "dblclick" (Json.Encode.object [])
                    , user.click 100 (Dom.id "guild_leaveVoiceChat")
                    , admin.checkView
                        50
                        (\html ->
                            Test.Html.Query.findAll [ Test.Html.Selector.exactText "started a call, lasted 1\u{00A0}minute" ] html
                                |> Test.Html.Query.count (Expect.equal 1)
                        )
                    , tallSnapshot user 100 { name = "Call ended" }
                    ]
                ]
            )
        ]
