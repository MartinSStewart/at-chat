module E2EVoiceChat exposing (startCall, voiceChatTest)

import Audio
import Call
import Codec
import Dict
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Lamdera as Lamdera
import Effect.Test as T exposing (PortToJs)
import Expect
import FileStatus
import Id exposing (Id, UserId)
import IdArray
import Json.Decode
import Json.Encode
import List.Extra
import Local
import LocalState exposing (CallStatus(..))
import Message exposing (CallRecording, CallRecordingFile, Message(..))
import MyUi
import NonemptyDict
import NonemptySet
import Pages.Guild
import RPC
import SecretId
import SeqDict
import SeqSet
import Test.Html.Query
import Test.Html.Selector
import Time
import Types exposing (BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)
import Url


{-| The url `ToJs_StartCall` carries is the one the browser would have opened.
Taking the room and client back out of it is how these tests stand in for the
rust server, which is otherwise what tells the backend somebody joined.

Built from the same `websocketDomain` `Call.startCallCmd` builds it from, so
that changing where the rust server lives cannot leave this quietly matching
nothing, which is what it did when it had the address written out by hand.

-}
isWebsocketRequest : PortToJs -> Maybe { clientId : Lamdera.ClientId, roomId : String }
isWebsocketRequest request =
    let
        prefix : String
        prefix =
            FileStatus.websocketDomain ++ "/file/websocket/"
    in
    if request.portName == "voice_chat_to_js" then
        case Codec.decodeValue Call.voiceChatToJsCodec request.value of
            Ok (Call.ToJs_StartCall ok) ->
                if String.startsWith prefix ok.websocketUrl then
                    case String.dropLeft (String.length prefix) ok.websocketUrl |> String.split "?clientId=" of
                        [ roomId, clientId ] ->
                            case ( Url.percentDecode roomId, Url.percentDecode clientId ) of
                                ( Just roomId2, Just clientId2 ) ->
                                    Just
                                        { clientId = Lamdera.clientIdFromString clientId2
                                        , roomId = roomId2
                                        }

                                _ ->
                                    Nothing

                        _ ->
                            Nothing

                else
                    Nothing

            _ ->
                Nothing

    else
        Nothing


{-| Clicking join only gets as far as opening a websocket, which in a test goes
nowhere. What the backend is actually waiting for is the rust server asking it
whether the caller may join, so that request is made here on the rust server's
behalf.

The session is the one owning the client that opened the socket, the same way
the real rust server takes it from that browser's `sid` cookie rather than from
anything the page chose.

-}
startCall :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
startCall actions =
    T.group
        [ actions.click 100 (Dom.id "guild_startVoiceChat")
        , T.andThen
            100
            (\data ->
                let
                    backend : Types.BackendModel
                    backend =
                        E2EHelper.unwrapBackend data.backend
                in
                case List.Extra.findMap isWebsocketRequest data.portRequests of
                    Just websocketRequest ->
                        case
                            SeqDict.toList backend.connections
                                |> List.Extra.find (\( _, conns ) -> NonemptyDict.member websocketRequest.clientId conns)
                                |> Maybe.andThen
                                    (\( sessionId, _ ) ->
                                        SeqDict.get sessionId backend.sessions
                                            |> Maybe.map (Tuple.pair sessionId)
                                    )
                        of
                            Just ( sessionId, session ) ->
                                case RPC.roomIdFromString session.userId websocketRequest.roomId of
                                    Just roomId ->
                                        [ T.backendUpdate
                                            0
                                            (Types.Rpc_UserJoinedCall
                                                data.time
                                                sessionId
                                                websocketRequest.clientId
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
        [ dmCallTest False normalConfig
        , dmCallTest True normalConfig
        , recordingNeedsEveryoneTest normalConfig
        , recordingNotStartedTest normalConfig
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
                        (Test.Html.Query.hasNot [ Test.Html.Selector.text Pages.Guild.startedACallText ])
                    , admin.click 100 (Dom.id "guild_voiceChat")
                    , startCall admin
                    , E2EHelper.tallSnapshot admin 100 { name = "Started a DM call with self" }
                    , admin.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.text Pages.Guild.startedACallText ])
                    , admin.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.text LocalState.callEndedText ])
                    , E2EHelper.tallSnapshot admin 100 { name = "Ended a DM call with self" }

                    -- Three steps back to the channel each time: the voice chat tab, the
                    -- DM, and opening the member column the DM was opened from.
                    , admin.navigateBack 100
                    , admin.navigateBack 100
                    , admin.navigateBack 100
                    , E2EHelper.openDm admin 100 "2"
                    , user.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.text Pages.Guild.startedACallText ])
                    , admin.click 100 (Dom.id "guild_voiceChat")
                    , startCall admin
                    , user.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.text Pages.Guild.startedACallText ])
                    , user.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.text LocalState.callEndedText ])
                    , admin.navigateBack 100
                    , admin.navigateBack 100
                    , admin.navigateBack 100
                    , E2EHelper.openDm admin 100 "0"
                    , admin.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.text Pages.Guild.startedACallText, Test.Html.Selector.text LocalState.callEndedText ])
                    , admin.click 100 (Dom.id "guild_voiceChat")
                    , startCall admin
                    , user.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.text Pages.Guild.startedACallText, Test.Html.Selector.text LocalState.callEndedText ])
                    ]
                )
            ]
        ]


{-| What the given client is currently drawing for the call: nothing, a local
preview, the full size call view or the minimized thumbnail.
-}
displayModeOf : Lamdera.ClientId -> T.Data FrontendModel E2EHelper.BackendModel2 -> Result String Call.DisplayMode
displayModeOf clientId data =
    case SeqDict.get clientId data.frontends |> Maybe.map Audio.userModel of
        Just (Types.Loaded loaded) ->
            case loaded.loginStatus of
                Types.LoggedIn loggedIn ->
                    let
                        local : LocalState.LocalState
                        local =
                            Local.model loggedIn.localState
                    in
                    Call.displayMode
                        (MyUi.isMobile loaded)
                        local.localUser.session.userId
                        loaded.route
                        local.calls
                        |> Ok

                Types.NotLoggedIn _ ->
                    Err "Expected user to be logged in"

        _ ->
            Err "Expected user frontend to be loaded"


dmCallTest :
    Bool
    -> T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
dmCallTest isMobile normalConfig =
    let
        -- A narrow window renders the mobile layout (touch events), a wide one
        -- the desktop layout (pointer events). See MyUi.isMobile.
        window : { width : Int, height : Int }
        window =
            if isMobile then
                E2EHelper.iphone14Window

            else
                E2EHelper.desktopWindow
    in
    E2EHelper.startTest
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
                [ if isMobile then
                    T.group
                        [ E2EHelper.setIphone14SafeAreaInsets admin
                        , E2EHelper.setIphone14SafeAreaInsets user
                        ]

                  else
                    T.group []
                , T.collapsableGroup
                    "Voice chat"
                    [ E2EHelper.openDm admin 100 "2"
                    , E2EHelper.openDm user 100 "0"
                    , admin.click 100 (Dom.id "guild_voiceChat")
                    , T.checkState 100 (E2EHelper.checkVoiceChatFromJsEvents E2EHelper.fromJsAfterAdminOpensVoiceChat)
                    , user.click 100 (Dom.id "guild_voiceChat")
                    , T.checkState 100 (E2EHelper.checkVoiceChatFromJsEvents E2EHelper.fromJsAfterUserOpensVoiceChat)
                    , startCall admin
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
                                        ("Expected one connection to be in the call once the admin joined, got "
                                            ++ String.fromInt (List.length other)
                                        )
                        )
                    , startCall user
                    , admin.checkView
                        50
                        (\html ->
                            Test.Html.Query.findAll [ Test.Html.Selector.exactText Pages.Guild.startedACallText ] html
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
                                        ("Expected both connections to be in the call once the user joined, got "
                                            ++ String.fromInt (List.length other)
                                        )
                        )
                    , E2EHelper.tallSnapshot user 100 { name = "Joined a DM call" }
                    , if isMobile then
                        T.group []

                      else
                        T.group
                            [ admin.click 100 (Dom.id "guild_voiceChatScreenShare")
                            , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Your screen" ])
                            , user.checkView 0 (Test.Html.Query.has [ Test.Html.Selector.text "'s screen" ])
                            , E2EHelper.tallSnapshot user 0 { name = "Watching a shared screen" }
                            , admin.click 100 (Dom.id "guild_voiceChatScreenShare")
                            , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Your screen" ])
                            , user.checkView 0 (Test.Html.Query.hasNot [ Test.Html.Selector.text "'s screen" ])
                            ]
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
                                    (SeqDict.toList (E2EHelper.unwrapBackend m).connections)
                            of
                                [ _, _ ] ->
                                    Ok ()

                                other ->
                                    Err
                                        ("Expected both connections to still be in the call at the end, got "
                                            ++ String.fromInt (List.length other)
                                        )
                        )
                    , -- The full size call view sits on top of the conversation view. On
                      -- mobile the conversation view can be swiped away without the route
                      -- changing, and once it's gone the call has to shrink down to the
                      -- thumbnail instead of staying spread over the channel list.
                      if isMobile then
                        T.group
                            [ user.click 100 (Dom.id "guild_headerBackButton")
                            , E2EHelper.tallSnapshot user 10 { name = "Call sliding away with the conversation view" }
                            , T.checkState
                                500
                                (\data ->
                                    case displayModeOf user.clientId data of
                                        Ok (Call.ShowLocalVideoAndCallThumbnail _) ->
                                            Ok ()

                                        Ok _ ->
                                            Err "Expected the call to shrink to a thumbnail once the conversation view was swiped closed"

                                        Err error ->
                                            Err error
                                )
                            , user.checkView 0 (Test.Html.Query.has [ Test.Html.Selector.id "call_videoThumbnail" ])
                            , E2EHelper.tallSnapshot user 0 { name = "Call thumbnail after swiping the conversation view closed" }
                            , -- Double clicking the thumbnail brings the conversation view
                              -- back, which puts the full size call view back on screen.
                              user.custom 100 (Dom.id "call_videoThumbnail") "dblclick" (Json.Encode.object [])
                            , T.checkState
                                500
                                (\data ->
                                    case displayModeOf user.clientId data of
                                        Ok (Call.ShowLocalVideoAndCall _) ->
                                            Ok ()

                                        Ok _ ->
                                            Err "Expected the full size call view to come back when the conversation view was reopened"

                                        Err error ->
                                            Err error
                                )
                            ]

                      else
                        T.group []
                    , user.click 100 (Dom.id "guild_voiceChat")
                    , E2EHelper.tallSnapshot user 100 { name = "Voice chat with tab closed" }

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
                    , E2EHelper.tallSnapshot user 100 { name = "Call ended" }
                    ]
                ]
            )
        ]


recordingStatuses : T.Data FrontendModel E2EHelper.BackendModel2 -> List Call.RecordingStatus
recordingStatuses data =
    SeqDict.values (E2EHelper.unwrapBackend data.backend).callRecordings


checkIsRecording : T.Data FrontendModel E2EHelper.BackendModel2 -> Result String ()
checkIsRecording data =
    case recordingStatuses data of
        [ Call.RecordingSince _ ] ->
            Ok ()

        _ ->
            Err "Expected the call to be recording"


checkIsAskingToRecord : T.Data FrontendModel E2EHelper.BackendModel2 -> Result String ()
checkIsAskingToRecord data =
    case recordingStatuses data of
        [ Call.AskingToRecord _ ] ->
            Ok ()

        _ ->
            Err "Expected the call to still be asking whether it can be recorded"


checkNoRecording : T.Data FrontendModel E2EHelper.BackendModel2 -> Result String ()
checkNoRecording data =
    case recordingStatuses data of
        [] ->
            Ok ()

        _ ->
            Err "Expected no call to have a recording status"


callRecordings : T.Data FrontendModel E2EHelper.BackendModel2 -> List ( Call.SharedCallId, CallRecording (Id UserId) )
callRecordings data =
    let
        backend : Types.BackendModel
        backend =
            E2EHelper.unwrapBackend data.backend

        fromMessages : Call.SharedCallId -> List (Message messageId (Id UserId) channelId) -> List ( Call.SharedCallId, CallRecording (Id UserId) )
        fromMessages sharedCallId messages =
            List.concatMap
                (\message ->
                    case message of
                        CallStarted callStarted ->
                            case callStarted.recordings of
                                Just recording ->
                                    [ ( sharedCallId, recording ) ]

                                Nothing ->
                                    []

                        _ ->
                            []
                )
                messages
    in
    List.concatMap
        (\( guildId, guild ) ->
            List.concatMap
                (\( channelId, channel ) ->
                    fromMessages (Call.SharedGuildCall { guildId = guildId, channelId = channelId }) (IdArray.toList channel.messages)
                )
                (SeqDict.toList guild.channels)
        )
        (SeqDict.toList backend.guilds)
        ++ List.concatMap
            (\( dmChannelId, dmChannel ) -> fromMessages (Call.SharedDmCall dmChannelId) (IdArray.toList dmChannel.messages))
            (SeqDict.toList backend.dmChannels)


checkCallRecording :
    { participants : List Int, files : List ( String, Int ) }
    -> T.Data FrontendModel E2EHelper.BackendModel2
    -> Result String ()
checkCallRecording expected data =
    case callRecordings data of
        [ ( _, recording ) ] ->
            let
                actual : { participants : List Int, files : List ( String, Int ) }
                actual =
                    { participants = NonemptySet.toList recording.participants |> List.map Id.toInt |> List.sort
                    , files = List.map (\file -> ( file.name, file.uploaded )) recording.files
                    }
            in
            if actual == expected then
                Ok ()

            else
                Err ("Expected the call's message to have the recording " ++ callRecordingToString expected ++ " but it had " ++ callRecordingToString actual)

        recordings ->
            Err ("Expected one recording on a call message but there were " ++ String.fromInt (List.length recordings))


checkFinishedUploading : List Int -> T.Data FrontendModel E2EHelper.BackendModel2 -> Result String ()
checkFinishedUploading expected data =
    case callRecordings data of
        [ ( _, recording ) ] ->
            let
                actual : List Int
                actual =
                    SeqSet.toList recording.finishedUploading |> List.map Id.toInt |> List.sort
            in
            if actual == expected then
                Ok ()

            else
                Err
                    ("Expected "
                        ++ String.join " " (List.map String.fromInt expected)
                        ++ " to have finished uploading but it was "
                        ++ String.join " " (List.map String.fromInt actual)
                    )

        recordings ->
            Err ("Expected one recording on a call message but there were " ++ String.fromInt (List.length recordings))


callRecordingToString : { participants : List Int, files : List ( String, Int ) } -> String
callRecordingToString recording =
    "participants "
        ++ String.join " " (List.map String.fromInt recording.participants)
        ++ ", files "
        ++ String.join " " (List.map (\( name, uploaded ) -> name ++ " (" ++ String.fromInt uploaded ++ ")") recording.files)


{-| What the backend tells the Rust server when it asks whether someone can upload a piece
of the call's recording.
-}
checkRecordingUpload : Lamdera.SessionId -> String -> Int -> T.Data FrontendModel E2EHelper.BackendModel2 -> Result String String
checkRecordingUpload sessionId fileName size data =
    case callRecordings data of
        [ ( sharedCallId, recording ) ] ->
            let
                backend : Types.BackendModel
                backend =
                    E2EHelper.unwrapBackend data.backend

                ( result, _, _ ) =
                    RPC.checkRecordingUpload
                        ""
                        backend
                        (Dict.singleton "x-secret-key" (SecretId.toString backend.serverSecret))
                        (Json.Encode.object
                            [ ( "sessionId", Json.Encode.string (Lamdera.sessionIdToString sessionId) )
                            , ( "file"
                              , Json.Encode.object
                                    [ ( "recordingId", Json.Encode.string (Call.recordingIdToString sharedCallId recording.startedAt) )
                                    , ( "name", Json.Encode.string fileName )
                                    , ( "startedAt", Json.Encode.int (Time.posixToMillis recording.startedAt) )
                                    , ( "endedAt", Json.Encode.int (Time.posixToMillis recording.startedAt + 1000) )
                                    , ( "size", Json.Encode.int size )
                                    ]
                              )
                            ]
                            |> Json.Encode.encode 0
                        )
            in
            Result.mapError (\_ -> "Upload refused") result

        _ ->
            Err "Expected one recording"


expectRecordingUpload : Result String String -> Lamdera.SessionId -> String -> Int -> T.Data FrontendModel E2EHelper.BackendModel2 -> Result String ()
expectRecordingUpload expected sessionId fileName size data =
    let
        actual : Result String String
        actual =
            checkRecordingUpload sessionId fileName size data
    in
    if actual == expected then
        Ok ()

    else
        Err ("Expected the upload check to give " ++ uploadCheckToString expected ++ " but it gave " ++ uploadCheckToString actual)


uploadCheckToString : Result String String -> String
uploadCheckToString result =
    case result of
        Ok ok ->
            "Ok " ++ ok

        Err error ->
            "Err " ++ error


recordingUploadProgress : Id UserId -> String -> Int -> Int -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
recordingUploadProgress userId fileName size uploaded =
    T.andThen
        100
        (\data ->
            case callRecordings data of
                [ ( sharedCallId, recording ) ] ->
                    let
                        file : CallRecordingFile (Id UserId)
                        file =
                            { recordedBy = userId
                            , name = fileName
                            , startedAt = recording.startedAt
                            , endedAt = Time.millisToPosix (Time.posixToMillis recording.startedAt + 1000)
                            , size = size
                            , uploaded = uploaded
                            }
                    in
                    [ T.backendUpdate 0 (Types.Rpc_RecordingUploadProgress sharedCallId recording.startedAt file) ]

                _ ->
                    [ T.checkBackend 0 (\_ -> Err "Expected one recording") ]
        )


{-| What the backend tells the Rust server once someone's device has uploaded everything it
recorded.
-}
expectRecordingUploadFinished :
    { hasNewFiles : Bool, isEveryoneFinished : Bool, fileCount : Int }
    -> Lamdera.SessionId
    -> T.Data FrontendModel E2EHelper.BackendModel2
    -> Result String ()
expectRecordingUploadFinished expected sessionId data =
    case callRecordings data of
        [ ( sharedCallId, recording ) ] ->
            let
                backend : Types.BackendModel
                backend =
                    E2EHelper.unwrapBackend data.backend

                ( result, _, _ ) =
                    RPC.recordingUploadFinished
                        ""
                        backend
                        (Dict.singleton "x-secret-key" (SecretId.toString backend.serverSecret))
                        (Json.Encode.object
                            [ ( "sessionId", Json.Encode.string (Lamdera.sessionIdToString sessionId) )
                            , ( "recordingId", Json.Encode.string (Call.recordingIdToString sharedCallId recording.startedAt) )
                            ]
                        )

                decoder : Json.Decode.Decoder { hasNewFiles : Bool, isEveryoneFinished : Bool, fileCount : Int }
                decoder =
                    Json.Decode.map3
                        (\hasNewFiles isEveryoneFinished fileCount ->
                            { hasNewFiles = hasNewFiles, isEveryoneFinished = isEveryoneFinished, fileCount = fileCount }
                        )
                        (Json.Decode.field "hasNewFiles" Json.Decode.bool)
                        (Json.Decode.field "isEveryoneFinished" Json.Decode.bool)
                        (Json.Decode.field "fileCount" Json.Decode.int)
            in
            case result of
                Ok json ->
                    case Json.Decode.decodeValue decoder json of
                        Ok actual ->
                            if actual == expected then
                                Ok ()

                            else
                                Err ("The upload finished reply wasn't what was expected: " ++ Json.Encode.encode 0 json)

                        Err error ->
                            Err (Json.Decode.errorToString error)

                Err _ ->
                    Err "Upload finished was refused"

        _ ->
            Err "Expected one recording"


recordingUploadFinished : Id UserId -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
recordingUploadFinished userId =
    T.andThen
        100
        (\data ->
            case callRecordings data of
                [ ( sharedCallId, recording ) ] ->
                    [ T.backendUpdate 0 (Types.Rpc_RecordingUploadFinished sharedCallId recording.startedAt userId) ]

                _ ->
                    [ T.checkBackend 0 (\_ -> Err "Expected one recording") ]
        )


recordingZipBuilt : String -> Int -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
recordingZipBuilt fileHash fileCount =
    T.andThen
        100
        (\data ->
            case callRecordings data of
                [ ( sharedCallId, recording ) ] ->
                    [ T.backendUpdate
                        0
                        (Types.Rpc_RecordingZipBuilt
                            sharedCallId
                            recording.startedAt
                            { fileHash = FileStatus.fileHash fileHash, size = 1000, fileCount = fileCount }
                        )
                    ]

                _ ->
                    [ T.checkBackend 0 (\_ -> Err "Expected one recording") ]
        )


isFileTracked : String -> T.Data FrontendModel E2EHelper.BackendModel2 -> Result String ()
isFileTracked fileHash data =
    if SeqDict.member (FileStatus.fileHash fileHash) (E2EHelper.unwrapBackend data.backend).files then
        Ok ()

    else
        Err "Expected the recording's zip to be tracked like any other file"


recordingNeedsEveryoneTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
recordingNeedsEveryoneTest normalConfig =
    E2EHelper.startTest
        "A call is only recorded once everyone in it allows it"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectFourUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin stevie joe wanda ->
                [ admin.click 100 (Dom.id "guild_voiceChat")
                , startCall admin
                , stevie.click 100 (Dom.id "guild_voiceChat")
                , startCall stevie
                , joe.click 100 (Dom.id "guild_voiceChat")
                , startCall joe
                , admin.click 100 (Dom.id "voiceChat_record")
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Asking everyone if this call can be recorded" ])
                , stevie.checkView 0 (Test.Html.Query.has [ Test.Html.Selector.text "wants to record this call" ])
                , joe.checkView 0 (Test.Html.Query.has [ Test.Html.Selector.text "wants to record this call" ])
                , E2EHelper.tallSnapshot stevie 0 { name = "Asked to allow a call recording" }

                -- Wanda isn't in the call, so isn't asked
                , wanda.checkView 0 (Test.Html.Query.hasNot [ Test.Html.Selector.text "wants to record this call" ])
                , stevie.click 100 (Dom.id "voiceChat_allowRecording")
                , stevie.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Waiting for everyone else to allow recording" ])
                , T.checkState 0 checkIsAskingToRecord
                , joe.click 100 (Dom.id "voiceChat_allowRecording")
                , T.checkState 100 checkIsRecording
                , T.checkState 0 (checkCallRecording { participants = [ 0, 2, 3 ], files = [] })
                , T.checkState 0 (expectRecordingUpload (Ok "valid,2") E2EHelper.sessionId1 "VIDEO_Stevie_2026-10-25_20-31-07.250.mp4" 1000)

                -- Wanda isn't in the recording yet, so can't upload to it
                , T.checkState 0 (expectRecordingUpload (Err "Upload refused") E2EHelper.sessionId4 "VIDEO_Wanda_2026-10-25_20-31-07.250.mp4" 1000)
                , admin.checkView 0 (Test.Html.Query.has [ Test.Html.Selector.text "This call is now being recorded" ])
                , admin.checkView 0 (Test.Html.Query.has [ Test.Html.Selector.id "voiceChat_recordingIndicator" ])
                , E2EHelper.tallSnapshot admin 0 { name = "Call recording started" }
                , wanda.click 100 (Dom.id "guild_voiceChat")
                , wanda.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Join\u{00A0}Recorded\u{00A0}Call" ])

                -- Joining a call that's being recorded is agreeing to it
                , startCall wanda
                , T.checkState 100 checkIsRecording
                , T.checkState 0 (checkCallRecording { participants = [ 0, 2, 3, 4 ], files = [] })
                , admin.click 100 (Dom.id "guild_leaveVoiceChat")
                , T.checkState 100 checkIsRecording
                , admin.checkView 0 (Test.Html.Query.has [ Test.Html.Selector.id "guild_callRecorded_3" ])

                -- Someone who leaves and comes back has more to upload
                , recordingUploadFinished (Id.fromInt 0)
                , T.checkState 100 (checkFinishedUploading [ 0 ])
                , startCall admin
                , T.checkState 100 (checkFinishedUploading [])
                , admin.click 100 (Dom.id "guild_leaveVoiceChat")

                -- A recording only ends with the call
                , joe.checkView 0 (Test.Html.Query.hasNot [ Test.Html.Selector.id "voiceChat_cancelRecording" ])
                , stevie.click 100 (Dom.id "guild_leaveVoiceChat")
                , joe.click 100 (Dom.id "guild_leaveVoiceChat")
                , T.checkState 100 checkIsRecording
                , wanda.click 100 (Dom.id "guild_leaveVoiceChat")
                , T.checkState 100 checkNoRecording
                , admin.checkView 0 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_callRecorded_3" ])
                , admin.checkView 0 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_callRecordings_3" ])
                , T.checkState 0 (checkCallRecording { participants = [ 0, 2, 3, 4 ], files = [] })

                -- Wanda is told not to leave while her part goes up
                , wanda.portEvent
                    10
                    "voice_chat_from_js"
                    (Json.Encode.object
                        [ ( "tag", Json.Encode.string "recording-upload-progress" )
                        , ( "args", Json.Encode.list Json.Encode.int [ 600000, 1000000 ] )
                        ]
                    )
                , wanda.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "voiceChat_recordingUpload" ])
                , E2EHelper.tallSnapshot wanda 0 { name = "Uploading a call recording" }
                , wanda.portEvent
                    10
                    "voice_chat_from_js"
                    (Json.Encode.object
                        [ ( "tag", Json.Encode.string "recording-uploads-stopped" )
                        , ( "args", Json.Encode.list Json.Encode.int [] )
                        ]
                    )
                , wanda.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "voiceChat_recordingUpload" ])

                -- Files go up after the recording has ended
                , T.checkState 0 (expectRecordingUpload (Ok "valid,4") E2EHelper.sessionId4 "VIDEO_Wanda_2026-10-25_20-31-07.250.mp4" 1000)
                , T.checkState 0 (expectRecordingUpload (Err "Upload refused") E2EHelper.sessionId4 "../secret.txt" 1000)
                , recordingUploadProgress (Id.fromInt 4) "VIDEO_Wanda_2026-10-25_20-31-07.250.mp4" 1000 0
                , recordingUploadProgress (Id.fromInt 4) "VIDEO_Wanda_2026-10-25_20-31-07.250.mp4" 1000 600
                , T.checkState 100 (checkCallRecording { participants = [ 0, 2, 3, 4 ], files = [ ( "VIDEO_Wanda_2026-10-25_20-31-07.250.mp4", 600 ) ] })

                -- A file can't change size partway through
                , T.checkState 0 (expectRecordingUpload (Err "Upload refused") E2EHelper.sessionId4 "VIDEO_Wanda_2026-10-25_20-31-07.250.mp4" 2000)
                , admin.checkView 0 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_callRecordings_3" ])
                , recordingUploadProgress (Id.fromInt 4) "VIDEO_Wanda_2026-10-25_20-31-07.250.mp4" 1000 1000

                -- Nothing to download until a zip has been made
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_callRecordings_3" ])
                , T.checkState 0 (expectRecordingUploadFinished { hasNewFiles = True, isEveryoneFinished = False, fileCount = 1 } E2EHelper.sessionId4)
                , recordingUploadFinished (Id.fromInt 4)
                , recordingZipBuilt "zipHash1" 1
                , T.checkState 100 (isFileTracked "zipHash1")
                , admin.checkView 0 (Test.Html.Query.has [ Test.Html.Selector.id "guild_callRecordings_3" ])

                -- The others haven't opened at-chat since, so their parts are missing
                , admin.checkView 0 (Test.Html.Query.has [ Test.Html.Selector.id "guild_callRecordingsMissing_3" ])
                , E2EHelper.tallSnapshot admin 0 { name = "Call recording ready to download" }

                -- Wanda's client added her to the recording when she joined, without being told separately
                , wanda.checkView 0 (Test.Html.Query.has [ Test.Html.Selector.id "guild_callRecordings_3" ])
                , recordingUploadFinished (Id.fromInt 0)
                , recordingUploadFinished (Id.fromInt 2)
                , T.checkState 100 (expectRecordingUploadFinished { hasNewFiles = False, isEveryoneFinished = True, fileCount = 1 } E2EHelper.sessionId2)
                , recordingUploadFinished (Id.fromInt 3)
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_callRecordingsMissing_3" ])
                , admin.checkView 0 (Test.Html.Query.has [ Test.Html.Selector.id "guild_callRecordings_3" ])

                -- Wanda joined after the call started, and can still delete its card
                , wanda.mouseEnter 100 (Dom.id "guild_message_3") ( 10, 10 ) []
                , wanda.custom
                    100
                    (Dom.id "miniView_showFullMenu")
                    "click"
                    (Json.Encode.object [ ( "clientX", Json.Encode.int 500 ), ( "clientY", Json.Encode.int 300 ) ])
                , wanda.click 100 (Dom.id "messageMenu_deleteMessage")
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_callRecordings_3" ])
                , admin.checkView 0 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_callStartedCard" ])

                -- With the card gone there's no recording left to upload to or download from
                , T.checkState
                    0
                    (\data ->
                        case callRecordings data of
                            [] ->
                                Ok ()

                            _ :: _ ->
                                Err "Expected the recording to be gone with its card"
                    )
                ]
            )
        ]


recordingNotStartedTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
recordingNotStartedTest normalConfig =
    E2EHelper.startTest
        "A DM call recording that's declined or goes unanswered isn't started"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                [ E2EHelper.openDm admin 100 "2"
                , E2EHelper.openDm user 100 "0"
                , admin.click 100 (Dom.id "guild_voiceChat")
                , startCall admin
                , user.click 100 (Dom.id "guild_voiceChat")
                , startCall user
                , admin.click 100 (Dom.id "voiceChat_record")
                , user.click 100 (Dom.id "voiceChat_declineRecording")
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Recording wasn't started because" ])
                , user.checkView 0 (Test.Html.Query.has [ Test.Html.Selector.text "Recording wasn't started because you declined" ])
                , E2EHelper.tallSnapshot admin 0 { name = "Call recording declined" }
                , admin.checkView 10000 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Recording wasn't started" ])

                -- Asking again and getting no answer
                , admin.click 100 (Dom.id "voiceChat_record")
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "wants to record this call" ])
                , T.checkState 30000 checkIsAskingToRecord
                , user.checkView
                    31000
                    (Test.Html.Query.has [ Test.Html.Selector.text "Recording wasn't started because not everyone answered in time" ])
                , user.checkView 0 (Test.Html.Query.hasNot [ Test.Html.Selector.text "wants to record this call" ])

                -- Somebody on their own has nobody else to ask
                , user.click 100 (Dom.id "guild_leaveVoiceChat")
                , admin.click 100 (Dom.id "voiceChat_record")
                , T.checkState 100 checkIsRecording
                , admin.click 100 (Dom.id "guild_leaveVoiceChat")
                , T.checkState 100 checkNoRecording
                ]
            )
        ]
