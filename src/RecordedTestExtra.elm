module RecordedTestExtra exposing
    ( CustomRequest
    , adminEmail
    , allAttackerLocalChanges
    , allAttackerToBackendChanges
    , andThenWebsocket
    , attackerEmail
    , attackerShouldNotGetThisToFrontend
    , botTestGuild
    , botTestGuild_ChannelA
    , checkNoNotification
    , checkNotification
    , chromeDesktop
    , clickSpoiler
    , cloudflareCostTest
    , connectTwoUsersAndJoinNewGuild
    , createThread
    , currentDiscordUserId
    , decodeCustomRequest
    , desktopWindow
    , discordUserAuth
    , domain
    , enableNotifications
    , firefoxDesktop
    , focusEvent
    , goMatchTest
    , goTurnNotificationDotTest
    , handleInternalRequests
    , handleLogin
    , handleLoginFromLoginPage
    , handlePortToJs
    , hasExactText
    , hasNotExactText
    , hasNotText
    , hasText
    , httpBasic
    , imageViewerTests
    , inactiveThreadsAreHiddenTest
    , infoEndpointResponse
    , inviteUser
    , inviteUserAndDmChat
    , isLogErrorEmail
    , isLoginEmail
    , isOp2
    , joeEmail
    , linkDiscordAndLogin
    , linkDiscordUrl
    , linkSecondDiscordAccount
    , loginTests
    , mobileWindow
    , mockCloudflareSfu
    , noMissingMessages
    , publicGoMatchViewTest
    , regeneratedServerSecretValue
    , safariIphone
    , scrollToMiddle
    , scrollToTop
    , secondDiscordToken
    , secondDiscordUserId
    , sessionId0
    , sessionId1
    , sessionId2
    , sessionIdAttacker
    , startTest
    , startTime
    , stringToJson
    , tallSnapshot
    , userEmail
    , voiceChatTest
    , websocketByDiscordToken
    , writeMessage
    , writeMessageMobile
    )

import AiChat exposing (AiModelName(..))
import Array
import Backend
import Broadcast
import Call
import ChannelDescription
import Cloudflare
import Codec
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Dict
import Discord
import Duration
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Lamdera as Lamdera exposing (SessionId)
import Effect.Test as T exposing (DelayInMs, HttpRequest, HttpResponse(..), RequestedBy(..))
import Effect.Websocket as Websocket
import EmailAddress exposing (EmailAddress)
import Emoji exposing (Category(..), EmojiOrCustomEmoji(..), SkinTone(..))
import Env
import Expect
import FileStatus
import Go
import Html.Attributes
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), DiscordGuildOrDmId_DmData, GuildId, GuildOrDmId(..), Id, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId)
import IdString
import ImageEditor
import Json.Decode
import Json.Encode
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import Local exposing (ChangeId(..))
import LocalState exposing (CallStatus(..))
import Log
import LoginForm
import NonemptyDict
import NonemptySet
import Pages.Admin
import Pages.Guild
import Pages.Home
import Parser exposing ((|.), (|=))
import PersonName
import Ports exposing (PushSubscriptionSource(..), RegisterPushSubscription(..))
import Range exposing (Range)
import RichText exposing (Domain(..))
import SafeJson exposing (SafeJson(..))
import SecretId exposing (SecretId(..))
import SeqDict
import SessionIdHash exposing (SessionIdHash(..))
import Slack
import String.Nonempty exposing (NonemptyString(..))
import Test.Html.Query
import Test.Html.Selector
import TextEditor
import Time
import TwoFactorAuthentication
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, InitialLoadRequest(..), LocalChange(..), LoginTokenData(..), ToBackend(..), ToFrontend(..))
import Unsafe
import Untrusted
import Url exposing (Protocol(..), Url)
import User
import UserAgent
import UserSession exposing (NotificationMode(..), SetViewing(..), ToBeFilledInByBackend(..))


domain : Url
domain =
    { protocol = Url.Http, host = "localhost", port_ = Just 8000, path = "", query = Nothing, fragment = Nothing }


stringToJson : String -> Json.Encode.Value
stringToJson json =
    Result.withDefault Json.Encode.null (Json.Decode.decodeString Json.Decode.value json)


handlePortToJs :
    { currentRequest : T.PortToJs, data : T.Data FrontendModel BackendModel }
    -> Maybe ( String, Json.Decode.Value )
handlePortToJs requestAndData =
    case requestAndData.currentRequest.portName of
        "voice_chat_to_js" ->
            mockVoiceChatPorts requestAndData

        "get_window_size" ->
            Just
                ( "got_window_size"
                , Json.Encode.object
                    [ ( "width", Json.Encode.float desktopWindow.width )
                    , ( "height", Json.Encode.float desktopWindow.height )
                    ]
                )

        "text_input_select_all_to_js" ->
            Nothing

        "check_notification_permission_to_js" ->
            Nothing

        "check_pwa_status_to_js" ->
            Just ( "check_pwa_status_from_js", Json.Encode.bool False )

        "load_sounds_to_js" ->
            Nothing

        "load_user_settings_to_js" ->
            Just ( "load_user_settings_from_js", Json.Encode.string "" )

        "copy_to_clipboard_to_js" ->
            Nothing

        "copy_image_to_clipboard_to_js" ->
            Nothing

        "register_push_subscription_to_js" ->
            ( "register_push_subscription_from_js"
            , Json.Encode.object
                [ ( "tag", Json.Encode.string "GotSubscribeData" )
                , ( "args"
                  , Json.Encode.list
                        identity
                        [ Json.Encode.string "UserEnabledNotifications"
                        , Json.Encode.object
                            [ ( "endpoint", Json.Encode.string "https://vapidserver.com/" )
                            , ( "expirationTime", Json.Encode.null )
                            , ( "keys"
                              , Json.Encode.object
                                    [ ( "auth", Json.Encode.string "123" )
                                    , ( "p256dh", Json.Encode.string "abc" )
                                    ]
                              )
                            ]
                        ]
                  )
                ]
            )
                |> Just

        "scrollbar_width_to_js" ->
            ( "scrollbar_width_from_js"
            , Json.Encode.int 20
            )
                |> Just

        "user_agent_to_js" ->
            Nothing

        _ ->
            let
                _ =
                    Debug.log "port request" requestAndData.currentRequest
            in
            Nothing


desktopWindow : { width : number, height : number }
desktopWindow =
    { width = 1000, height = 600 }


tallDesktopWindow : { width : number, height : number }
tallDesktopWindow =
    { width = 1000, height = 1300 }


mobileWindow : { width : number, height : number }
mobileWindow =
    { width = 400, height = 800 }


parseLoginCode : Parser.Parser Int
parseLoginCode =
    Parser.succeed identity
        |. Parser.symbol "Here is your code "
        |= Parser.int


decodePostmark : Json.Decode.Decoder ( String, EmailAddress, String )
decodePostmark =
    Json.Decode.map3 (\subject to body -> ( subject, to, body ))
        (Json.Decode.field "Subject" Json.Decode.string)
        (Json.Decode.field "To" Json.Decode.string
            |> Json.Decode.andThen
                (\to ->
                    case EmailAddress.fromString to of
                        Just emailAddress ->
                            Json.Decode.succeed emailAddress

                        Nothing ->
                            Json.Decode.fail "Invalid email address"
                )
        )
        (Json.Decode.field "TextBody" Json.Decode.string)


isLogErrorEmail : EmailAddress -> HttpRequest -> Maybe String
isLogErrorEmail emailAddress httpRequest =
    if httpRequest.url == "https://api.postmarkapp.com/email" then
        case httpRequest.body of
            T.JsonBody value ->
                case Json.Decode.decodeValue decodePostmark value of
                    Ok ( subject, to, body ) ->
                        case ( emailAddress == to, subject, String.split ":" body ) of
                            ( True, "An error was logged that needs attention", [ _, log ] ) ->
                                String.split "." log |> List.head |> Maybe.map String.trim

                            _ ->
                                Nothing

                    Err _ ->
                        Nothing

            _ ->
                Nothing

    else
        Nothing


isLoginEmail : EmailAddress -> HttpRequest -> Maybe Int
isLoginEmail emailAddress httpRequest =
    if httpRequest.url == "https://api.postmarkapp.com/email" then
        case httpRequest.body of
            T.JsonBody value ->
                case Json.Decode.decodeValue decodePostmark value of
                    Ok ( subject, to, body ) ->
                        case ( emailAddress == to, subject, Parser.run parseLoginCode body ) of
                            ( True, "Login code", Ok loginCode ) ->
                                Just loginCode

                            _ ->
                                Nothing

                    Err _ ->
                        Nothing

            _ ->
                Nothing

    else
        Nothing


sessionId0 : SessionId
sessionId0 =
    Lamdera.sessionIdFromString "sessionId0"


sessionId1 : SessionId
sessionId1 =
    Lamdera.sessionIdFromString "sessionId1"


sessionId2 : SessionId
sessionId2 =
    Lamdera.sessionIdFromString "sessionId2"


sessionIdAttacker : SessionId
sessionIdAttacker =
    Lamdera.sessionIdFromString "sessionId3"


handleLogin :
    String
    -> EmailAddress
    -> T.FrontendActions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> T.Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
handleLogin userAgent emailAddress client =
    [ client.portEvent 10 "user_agent_from_js" (Json.Encode.string userAgent)
    , client.click 100 Pages.Home.loginButtonId
    , handleLoginFromLoginPage emailAddress client
    ]
        |> T.group


handleLoginFromLoginPage :
    EmailAddress
    -> T.FrontendActions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> T.Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
handleLoginFromLoginPage emailAddress client =
    [ client.input 100 LoginForm.emailInputId (EmailAddress.toString emailAddress)
    , client.click 100 LoginForm.submitEmailButtonId
    , T.andThen
        100
        (\data ->
            case List.filterMap (isLoginEmail emailAddress) data.httpRequests of
                loginCode :: _ ->
                    [ client.input 100 LoginForm.loginCodeInputId (String.fromInt loginCode) ]

                _ ->
                    [ T.checkState 100 (\_ -> Err "Didn't find login email") ]
        )
    ]
        |> T.collapsableGroup "Login from login page"


startTime : Time.Posix
startTime =
    Time.millisToPosix 0


adminEmail : EmailAddress
adminEmail =
    Backend.adminUser.email


userEmail : EmailAddress
userEmail =
    Unsafe.emailAddress "user@mail.com"


joeEmail : EmailAddress
joeEmail =
    Unsafe.emailAddress "joe@hotmail.com"


attackerEmail : EmailAddress
attackerEmail =
    Unsafe.emailAddress "hacker-joe@hotmail.com"


regeneratedServerSecretValue : String
regeneratedServerSecretValue =
    "regenerated-server-secret-from-rust-server"


enableNotifications : Bool -> T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
enableNotifications isMobile user =
    [ user.click 100 (Dom.id "guild_showUserOptions")
    , user.keyUp 100 (Dom.id "userOptions_notificationMode") "ArrowDown" []
    , if isMobile then
        T.group []

      else
        user.keyUp 100 (Dom.id "userOptions_notificationMode") "ArrowDown" []
    , user.click 100 (Dom.id "userOptions_closeUserOptions")
    ]
        |> T.group


checkNotification : String -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
checkNotification body =
    T.checkState
        100
        (\data ->
            case
                List.filter
                    (\request ->
                        case request.body of
                            T.JsonBody json ->
                                case Codec.decodeValue Broadcast.pushNotificationCodec json of
                                    Ok pushNotification ->
                                        (pushNotification.body == body)
                                            && (request.url == "http://localhost:3000/file/internal/push-notification")

                                    Err _ ->
                                        False

                            _ ->
                                False
                    )
                    data.httpRequests
            of
                _ :: _ :: _ ->
                    Err ("Multiple notifications found for \"" ++ body ++ "\"")

                [ _ ] ->
                    Ok ()

                [] ->
                    Err ("Notification not found for \"" ++ body ++ "\"")
        )


httpBasic : String -> Int -> String -> HttpResponse
httpBasic url statusCode body =
    StringHttpResponse
        { url = url
        , statusCode = statusCode
        , statusText =
            case statusCode of
                200 ->
                    "OK"

                201 ->
                    "OK"

                _ ->
                    "Bad request"
        , headers = Dict.empty
        }
        body


{-| Mock Cloudflare Realtime SFU API. Used as a fall-through in the SFU
test's `handleHttpRequest`. Returns:

  - /sessions/new → 201 with sessionId "sfu-session-N", where N is the
    count of connections that already have callSfu set
    when the request hits (so deterministic per test
    step).
  - /tracks/new → 200 with either a publish answer (when the body
    carries a sessionDescription, i.e. push) or a pull
    offer (when it doesn't, i.e. pull).
  - /renegotiate → 200 empty body.

Anything else → Nothing so the caller can fall through to the normal HTTP
handler.

-}
mockCloudflareSfu :
    List String
    -> { currentRequest : HttpRequest, data : T.Data FrontendModel BackendModel }
    -> HttpResponse
mockCloudflareSfu path { currentRequest, data } =
    let
        sessionsWithCallSfu : Int
        sessionsWithCallSfu =
            SeqDict.foldl
                (\_ conns acc ->
                    NonemptyDict.toList conns
                        |> List.filter
                            (\( _, c ) ->
                                case c.call of
                                    ConnectedToCall _ _ ->
                                        True

                                    NotInCall ->
                                        False

                                    ConnectingToCall _ ->
                                        False
                            )
                        |> List.length
                        |> (+) acc
                )
                0
                data.backend.connections

        bodyJson : Json.Decode.Value
        bodyJson =
            case currentRequest.body of
                T.JsonBody value ->
                    value

                _ ->
                    Json.Encode.null
    in
    case path of
        [ "sessions", "new" ] ->
            httpBasic
                currentRequest.url
                201
                ("{\"sessionId\":\"sfu-session-"
                    ++ String.fromInt sessionsWithCallSfu
                    ++ "\"}"
                )

        [ "sessions", realtimeSessionId, "tracks", "new" ] ->
            case Json.Decode.decodeValue (Json.Decode.field "sessionDescription" Json.Decode.value) bodyJson of
                Ok _ ->
                    -- publish: client sent us an offer; we return an answer + assigned trackNames
                    "{\"sessionDescription\":{\"sdp\":\"answer-sdp-from-"
                        ++ realtimeSessionId
                        ++ "\",\"type\":\"answer\"},\"tracks\":[{\"trackName\":\"0\"},{\"trackName\":\"1\"}]}"
                        |> httpBasic currentRequest.url 200

                Err _ ->
                    -- pull: client asked for someone else's tracks; we return an offer the client must answer
                    "{\"sessionDescription\":{\"sdp\":\"pull-offer-sdp-from-"
                        ++ realtimeSessionId
                        ++ "\",\"type\":\"offer\"},\"requiresImmediateRenegotiation\":true}"
                        |> httpBasic currentRequest.url 200

        [ "sessions", _, "renegotiate" ] ->
            httpBasic currentRequest.url 200 ""

        _ ->
            UnhandledHttpRequest


mockVoiceChatPorts :
    { data : T.Data FrontendModel BackendModel, currentRequest : T.PortToJs }
    -> Maybe ( String, Json.Decode.Value )
mockVoiceChatPorts request =
    case Codec.decodeValue Call.voiceChatToJsCodec request.currentRequest.value of
        Ok ok ->
            case ok of
                Call.ToJs_StartCall _ ->
                    -- JS would: getUserMedia + addTransceiver(audio,video) + createOffer
                    -- + setLocalDescription, then send the offer SDP back.
                    -- The mids match what RTCPeerConnection auto-assigns ("0", "1").
                    fromJsEvent
                        (Call.FromJs_PublishOffer
                            (Cloudflare.sdpFromString "fake-publish-offer-sdp")
                            [ "0", "1" ]
                        )

                Call.ToJs_LeaveCall ->
                    -- JS closes the PC and stops local media. No response.
                    Nothing

                Call.ToJs_PublishAnswer _ ->
                    -- JS sets the SDP answer as the remote description and waits
                    -- for the PeerConnection to actually connect to Cloudflare.
                    -- Once connected it tells the backend (FromJs_PublishConnected),
                    -- which then drives the bidirectional track pulls via
                    -- Server_Joined → ToJs_PeerJoined. We simulate "connected"
                    -- firing immediately.
                    fromJsEvent Call.FromJs_PublishConnected

                Call.ToJs_PeerJoined { connectionId, sessionId, trackNames } ->
                    -- A peer joined while we're in the call. JS reacts by asking
                    -- Elm to pull that peer's tracks.
                    fromJsEvent (Call.FromJs_RequestPullTracks connectionId sessionId trackNames)

                Call.ToJs_PeerLeft _ ->
                    -- JS removes the peer's video element and stops their tracks.
                    -- No response.
                    Nothing

                Call.ToJs_AcceptPullOffer args ->
                    -- JS setRemoteDescription(offer) + createAnswer + setLocalDescription,
                    -- then sends the answer back so Elm can call /renegotiate.
                    fromJsEvent
                        (Call.FromJs_PullAnswer
                            args.connectionId
                            (Cloudflare.sdpFromString "fake-pull-answer-sdp")
                        )

                Call.ToJs_SetAudioInputEnabled _ ->
                    -- JS flips track.enabled in place. No response.
                    Nothing

                Call.ToJs_SetInput _ _ ->
                    -- JS replaces the track on the sender. No response.
                    Nothing

                Call.ToJs_SetVideoInputEnabled _ ->
                    -- Same as SetAudioInputEnabled. No response.
                    Nothing

                Call.ToJs_GetMediaDevices ->
                    fromJsEvent
                        (Call.FromJs_GotUserMediaDevices
                            [ { deviceId = IdString.fromString "microphoneDeviceId"
                              , groupId = "microphoneGroupId"
                              , kind = Call.AudioInput
                              , label = "Default microphone"
                              }
                            , { deviceId = IdString.fromString "webcameraDeviceId"
                              , groupId = "webcameraGroupId"
                              , kind = Call.VideoInput
                              , label = "Default webcamera"
                              }
                            , { deviceId = IdString.fromString "speakersDeviceId"
                              , groupId = "speakersGroupId"
                              , kind = Call.AudioOutput
                              , label = "Default speakers"
                              }
                            ]
                            [ IdString.fromString "microphoneDeviceId"
                            , IdString.fromString "webcameraDeviceId"
                            , IdString.fromString "speakersDeviceId"
                            ]
                        )

                Call.ToJs_StartLocalStream _ ->
                    fromJsEvent
                        (Call.FromJs_GotUserMediaDevices
                            [ { deviceId = IdString.fromString "microphoneDeviceId"
                              , groupId = "microphoneGroupId"
                              , kind = Call.AudioInput
                              , label = "Default microphone"
                              }
                            , { deviceId = IdString.fromString "webcameraDeviceId"
                              , groupId = "webcameraGroupId"
                              , kind = Call.VideoInput
                              , label = "Default webcamera"
                              }
                            , { deviceId = IdString.fromString "speakersDeviceId"
                              , groupId = "speakersGroupId"
                              , kind = Call.AudioOutput
                              , label = "Default speakers"
                              }
                            ]
                            [ IdString.fromString "microphoneDeviceId"
                            , IdString.fromString "webcameraDeviceId"
                            , IdString.fromString "speakersDeviceId"
                            ]
                        )

                Call.ToJs_StopLocalStream ->
                    -- JS stops tracks. No response.
                    Nothing

                Call.ToJs_SetVolume _ _ ->
                    -- JS sets element.volume. No response.
                    Nothing

        Err error ->
            let
                _ =
                    Debug.log "Failed to decode Call.toJs" (Json.Decode.errorToString error)
            in
            Nothing


fromJsEvent : Call.FromJs -> Maybe ( String, Json.Decode.Value )
fromJsEvent value =
    Just ( "voice_chat_from_js", Call.encodeFromJs value )


{-| Regression guard for the JS → Elm side of the voice-chat handshake.

Every `voice_chat_to_js` message the frontend emits is fed through the same
`mockVoiceChatPorts` JS simulation the test uses, and the resulting
`voice_chat_from_js` payloads are captured as JSON. `sfuHandshakeTest` then
asserts the exact ordered list of from-JS payloads _after each step that is
meant to trigger one_, so that an event firing later than it should (or not at
all) fails the check at the point where it was expected — not silently at the
end. If a refactor changes which to-JS messages are emitted (or their shape),
the derived from-JS events change and the relevant checkpoint fails.

-}
fromJs_GotMediaDevices : String
fromJs_GotMediaDevices =
    "{\"tag\":\"got-media-devices\",\"args\":[[{\"deviceId\":\"microphoneDeviceId\",\"groupId\":\"microphoneGroupId\",\"kind\":\"audioinput\",\"label\":\"Default microphone\"},{\"deviceId\":\"webcameraDeviceId\",\"groupId\":\"webcameraGroupId\",\"kind\":\"videoinput\",\"label\":\"Default webcamera\"},{\"deviceId\":\"speakersDeviceId\",\"groupId\":\"speakersGroupId\",\"kind\":\"audiooutput\",\"label\":\"Default speakers\"}],[\"microphoneDeviceId\",\"webcameraDeviceId\",\"speakersDeviceId\"]]}"


fromJs_PublishOffer : String
fromJs_PublishOffer =
    "{\"tag\":\"publish-offer\",\"args\":[\"fake-publish-offer-sdp\",[\"0\",\"1\"]]}"


fromJs_PublishConnected : String
fromJs_PublishConnected =
    "{\"tag\":\"publish-connected\",\"args\":[]}"


fromJs_RequestPullTracksSession1 : String
fromJs_RequestPullTracksSession1 =
    "{\"tag\":\"request-pull-tracks\",\"args\":[{\"roomId\":\"1\",\"otherClientId\":\"1 clientId 2\"},\"sfu-session-1\",[\"0\",\"1\"]]}"


fromJs_RequestPullTracksSession0 : String
fromJs_RequestPullTracksSession0 =
    "{\"tag\":\"request-pull-tracks\",\"args\":[{\"roomId\":\"0\",\"otherClientId\":\"0 clientId 1\"},\"sfu-session-0\",[\"0\",\"1\"]]}"


fromJs_PullAnswerSession1 : String
fromJs_PullAnswerSession1 =
    "{\"tag\":\"pull-answer\",\"args\":[{\"roomId\":\"1\",\"otherClientId\":\"1 clientId 2\"},\"fake-pull-answer-sdp\"]}"


fromJs_PullAnswerSession0 : String
fromJs_PullAnswerSession0 =
    "{\"tag\":\"pull-answer\",\"args\":[{\"roomId\":\"0\",\"otherClientId\":\"0 clientId 1\"},\"fake-pull-answer-sdp\"]}"


{-| Cumulative `voice_chat_from_js` payloads expected at each handshake
checkpoint. Each value extends the previous one with the events that step is
supposed to add, so the checks pin down _when_ each event fires, not just that
it eventually does.
-}
fromJsAfterAdminOpensVoiceChat : List String
fromJsAfterAdminOpensVoiceChat =
    [ fromJs_GotMediaDevices ]


fromJsAfterUserOpensVoiceChat : List String
fromJsAfterUserOpensVoiceChat =
    fromJsAfterAdminOpensVoiceChat ++ [ fromJs_GotMediaDevices ]


fromJsAfterAdminPublishes : List String
fromJsAfterAdminPublishes =
    fromJsAfterUserOpensVoiceChat ++ [ fromJs_PublishOffer, fromJs_PublishConnected ]


fromJsAfterUserPublishes : List String
fromJsAfterUserPublishes =
    fromJsAfterAdminPublishes
        ++ [ fromJs_PublishOffer
           , fromJs_PublishConnected
           , fromJs_RequestPullTracksSession1
           , fromJs_RequestPullTracksSession0
           ]


fromJsAfterPullsComplete : List String
fromJsAfterPullsComplete =
    fromJsAfterUserPublishes ++ [ fromJs_PullAnswerSession1, fromJs_PullAnswerSession0 ]


{-| Assert the exact ordered list of `voice_chat_from_js` payloads that have
been produced so far equals `expected`. Placed at each handshake checkpoint so
the prefix is pinned down step by step.
-}
checkVoiceChatFromJsEvents : List String -> T.Data FrontendModel BackendModel -> Result String ()
checkVoiceChatFromJsEvents expected data =
    let
        actual : List String
        actual =
            voiceChatFromJsPayloads data
    in
    if actual == expected then
        Ok ()

    else
        Err
            ("voice_chat_from_js events not as expected at this step.\nExpected:\n  "
                ++ String.join "\n  " expected
                ++ "\nActual:\n  "
                ++ String.join "\n  " actual
            )


voiceChatFromJsPayloads : T.Data FrontendModel BackendModel -> List String
voiceChatFromJsPayloads data =
    data.portRequests
        |> List.reverse
        |> List.filterMap
            (\request ->
                if request.portName == "voice_chat_to_js" then
                    case mockVoiceChatPorts { data = data, currentRequest = request } of
                        Just ( _, value ) ->
                            Just (Json.Encode.encode 0 value)

                        Nothing ->
                            Nothing

                else
                    Nothing
            )



--{"tag":"got-media-devices","args":[[{"deviceId":"microphoneDeviceId","groupId":"microphoneGroupId","kind":"audioinput","label":"Default microphone"},{"deviceId":"webcameraDeviceId","groupId":"webcameraGroupId","kind":"videoinput","label":"Default webcamera"},{"deviceId":"speakersDeviceId","groupId":"speakersGroupId","kind":"audiooutput","label":"Default speakers"}],["microphoneDeviceId","webcameraDeviceId","speakersDeviceId"]]}
--{"tag":"got-media-devices","args":[[{"deviceId":"microphoneDeviceId","groupId":"microphoneGroupId","kind":"audioinput","label":"Default microphone"},{"deviceId":"webcameraDeviceId","groupId":"webcameraGroupId","kind":"videoinput","label":"Default webcamera"},{"deviceId":"speakersDeviceId","groupId":"speakersGroupId","kind":"audiooutput","label":"Default speakers"}],["microphoneDeviceId","webcameraDeviceId","speakersDeviceId"]]}
--{"tag":"publish-offer","args":["fake-publish-offer-sdp",["0","1"]]}
--{"tag":"publish-connected","args":[]}
--{"tag":"publish-offer","args":["fake-publish-offer-sdp",["0","1"]]}
--{"tag":"publish-connected","args":[]}
--{"tag":"request-pull-tracks","args":[{"roomId":"1","otherClientId":"1 clientId 2"},"sfu-session-1",["0","1"]]}
--{"tag":"request-pull-tracks","args":[{"roomId":"0","otherClientId":"0 clientId 1"},"sfu-session-0",["0","1"]]}
--{"tag":"got-media-devices","args":[[{"deviceId":"microphoneDeviceId","groupId":"microphoneGroupId","kind":"audioinput","label":"Default microphone"},{"deviceId":"webcameraDeviceId","groupId":"webcameraGroupId","kind":"videoinput","label":"Default webcamera"},{"deviceId":"speakersDeviceId","groupId":"speakersGroupId","kind":"audiooutput","label":"Default speakers"}],["microphoneDeviceId","webcameraDeviceId","speakersDeviceId"]]}
--{"tag":"got-media-devices","args":[[{"deviceId":"microphoneDeviceId","groupId":"microphoneGroupId","kind":"audioinput","label":"Default microphone"},{"deviceId":"webcameraDeviceId","groupId":"webcameraGroupId","kind":"videoinput","label":"Default webcamera"},{"deviceId":"speakersDeviceId","groupId":"speakersGroupId","kind":"audiooutput","label":"Default speakers"}],["microphoneDeviceId","webcameraDeviceId","speakersDeviceId"]]}
--{"tag":"publish-offer","args":["fake-publish-offer-sdp",["0","1"]]}
--{"tag":"publish-connected","args":[]}
--{"tag":"publish-offer","args":["fake-publish-offer-sdp",["0","1"]]}
--{"tag":"publish-connected","args":[]}
--{"tag":"request-pull-tracks","args":[{"roomId":"1","otherClientId":"1 clientId 2"},"sfu-session-1",["0","1"]]}
--{"tag":"request-pull-tracks","args":[{"roomId":"0","otherClientId":"0 clientId 1"},"sfu-session-0",["0","1"]]}
--{"tag":"pull-answer","args":[{"roomId":"1","otherClientId":"1 clientId 2"},"fake-pull-answer-sdp"]}
--{"tag":"pull-answer","args":[{"roomId":"0","otherClientId":"0 clientId 1"},"fake-pull-answer-sdp"]}


addCloudflareRealtimeApiKeys :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
addCloudflareRealtimeApiKeys admin =
    T.collapsableGroup
        "Add Cloudflare Realtime API keys"
        [ admin.click 100 (Dom.id "guild_showUserOptions")
        , admin.click 100 (Dom.id "userOptions_gotoAdmin")
        , admin.click 100 (Dom.id "admin_expandSectionButton_API keys")
        , admin.input 100 (Dom.id "userOptions_cloudflareRealtimeAppId_label") "test-app-id"
        , admin.click 100 (Dom.id "userOptions_cloudflareRealtimeAppId_acceptEdit")
        , admin.input 100 (Dom.id "userOptions_cloudflareRealtimeApiToken_label") "test-api-token"
        , admin.click 100 (Dom.id "userOptions_cloudflareRealtimeApiToken_acceptEdit")
        , admin.navigateBack 100
        , T.checkBackend 100
            (\m ->
                case ( m.cloudflareRealtimeAppId, m.cloudflareRealtimeApiToken ) of
                    ( Just _, Just _ ) ->
                        Ok ()

                    _ ->
                        Err "Cloudflare keys did not land on the backend"
            )
        ]


{-| Configure the Cloudflare account id and analytics API token (used for the monthly cost check)
through the admin page.
-}
addCloudflareAnalyticsApiKeys :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
addCloudflareAnalyticsApiKeys admin =
    T.collapsableGroup
        "Add Cloudflare analytics API keys"
        [ admin.click 100 (Dom.id "guild_showUserOptions")
        , admin.click 100 (Dom.id "userOptions_gotoAdmin")
        , admin.click 100 (Dom.id "admin_expandSectionButton_API keys")
        , admin.input 100 (Dom.id "userOptions_cloudflareAccountId_label") "test-account-id"
        , admin.click 100 (Dom.id "userOptions_cloudflareAccountId_acceptEdit")
        , admin.input 100 (Dom.id "userOptions_cloudflareAnalyticsApiToken_label") "test-analytics-token"
        , admin.click 100 (Dom.id "userOptions_cloudflareAnalyticsApiToken_acceptEdit")
        , admin.navigateBack 100
        , T.checkBackend 100
            (\m ->
                case ( m.cloudflareAccountId, m.cloudflareAnalyticsApiToken ) of
                    ( Just _, Just _ ) ->
                        Ok ()

                    _ ->
                        Err "Cloudflare analytics keys did not land on the backend"
            )
        ]


cloudflareCostTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
cloudflareCostTest config =
    startTest
        "Cloudflare cost alert logs and emails the admin"
        startTime
        config
        [ T.connectFrontend
            100
            sessionId0
            "/"
            desktopWindow
            (\admin ->
                [ handleLogin firefoxDesktop adminEmail admin
                , addCloudflareAnalyticsApiKeys admin

                -- The admin can also load current egress on demand from the voice chat section.
                , admin.click 100 (Dom.id "guild_showUserOptions")
                , admin.click 100 (Dom.id "userOptions_gotoAdmin")
                , admin.click 100 (Dom.id "admin_expandSectionButton_Voice chat")
                , admin.click 100 (Dom.id "admin_loadCloudflareEgress")
                , hasText admin [ "1100.00 GB used (estimated $5.00 this month)" ]
                , admin.navigateBack 100
                ]
            )
        , -- The hourly job queries Cloudflare (mocked to return 1100 GB of egress => $5.00/month).
          T.backendUpdate 100 (Types.HourlyUpdate startTime)
        , T.checkBackend 200
            (\m ->
                if
                    Array.toList m.logs
                        |> List.any
                            (\entry ->
                                case entry.log of
                                    Log.CloudflareCostExceeded _ _ ->
                                        True

                                    _ ->
                                        False
                            )
                then
                    Ok ()

                else
                    Err "Expected a CloudflareCostExceeded log to be recorded"
            )
        , T.checkState 200
            (\data ->
                case List.filterMap (isLogErrorEmail adminEmail) data.httpRequests of
                    log :: _ ->
                        if String.startsWith "Cloudflare services are estimated to cost" log then
                            Ok ()

                        else
                            Err ("Unexpected error email body: " ++ log)

                    [] ->
                        Err "Expected an error-notification email about Cloudflare costs"
            )
        ]


voiceChatTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
voiceChatTest normalConfig =
    T.testGroup
        "Voice chat"
        [ startTest
            "SFU handshake — two users join a 1:1 call"
            startTime
            normalConfig
            [ connectTwoUsersAndJoinNewGuild desktopWindow
                (\admin user ->
                    [ T.collapsableGroup
                        "Voice chat"
                        [ addCloudflareRealtimeApiKeys admin
                        , admin.click 100 (Dom.id "guild_openDm_1")
                        , user.click 100 (Dom.id "guild_openDm_0")
                        , admin.click 100 (Dom.id "guild_voiceChat")
                        , T.checkState 100 (checkVoiceChatFromJsEvents fromJsAfterAdminOpensVoiceChat)
                        , user.click 100 (Dom.id "guild_voiceChat")
                        , T.checkState 100 (checkVoiceChatFromJsEvents fromJsAfterUserOpensVoiceChat)
                        , admin.click 100 (Dom.id "guild_startVoiceChat")
                        , tallSnapshot admin 100 { name = "Started a DM call" }
                        , T.checkBackend 200
                            (\m ->
                                case
                                    List.concatMap
                                        (\( _, conns ) ->
                                            List.filter
                                                (\( _, c ) ->
                                                    case c.call of
                                                        ConnectedToCall _ _ ->
                                                            True

                                                        NotInCall ->
                                                            False

                                                        ConnectingToCall _ ->
                                                            False
                                                )
                                                (NonemptyDict.toList conns)
                                        )
                                        (SeqDict.toList m.connections)
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
                        , T.checkBackend 200
                            (\m ->
                                case
                                    List.concatMap
                                        (\( _, conns ) ->
                                            List.filter
                                                (\( _, c ) ->
                                                    case c.call of
                                                        ConnectedToCall _ _ ->
                                                            True

                                                        NotInCall ->
                                                            False

                                                        ConnectingToCall _ ->
                                                            False
                                                )
                                                (NonemptyDict.toList conns)
                                        )
                                        (SeqDict.toList m.connections)
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
                        , tallSnapshot user 100 { name = "Joined a DM call" }
                        , T.checkBackend 500
                            (\m ->
                                case
                                    List.concatMap
                                        (\( _, conns ) ->
                                            List.filter
                                                (\( _, c ) ->
                                                    case c.call of
                                                        ConnectedToCall _ _ ->
                                                            True

                                                        NotInCall ->
                                                            False

                                                        ConnectingToCall _ ->
                                                            False
                                                )
                                                (NonemptyDict.toList conns)
                                        )
                                        (SeqDict.toList m.connections)
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
                        , admin.click 100 (Dom.id "guild_leaveVoiceChat")
                        , tallSnapshot admin 100 { name = "Left a DM call admin perspective" }
                        , tallSnapshot user 100 { name = "Left a DM call user perspective" }
                        ]
                    ]
                )
            ]
        , startTest
            "Hop between voice calls"
            startTime
            normalConfig
            [ connectTwoUsersAndJoinNewGuild
                desktopWindow
                (\admin user ->
                    [ addCloudflareRealtimeApiKeys admin
                    , admin.click 100 (Dom.id "guild_openDm_0")
                    , user.click 100 (Dom.id "guild_openDm_0")
                    , admin.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.text "started a call" ])
                    , admin.click 100 (Dom.id "guild_voiceChat")
                    , admin.click 100 (Dom.id "guild_startVoiceChat")
                    , tallSnapshot admin 100 { name = "Started a DM call with self" }
                    , admin.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.text "started a call" ])
                    , admin.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.text "Call ended" ])
                    , tallSnapshot admin 100 { name = "Ended a DM call with self" }
                    , admin.navigateBack 100
                    , admin.navigateBack 100
                    , admin.click 100 (Dom.id "guild_openDm_1")
                    , user.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.text "started a call" ])
                    , admin.click 100 (Dom.id "guild_voiceChat")
                    , admin.click 100 (Dom.id "guild_startVoiceChat")
                    , user.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.text "started a call" ])
                    , user.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.text "Call ended" ])
                    , admin.navigateBack 100
                    , admin.navigateBack 100
                    , admin.click 100 (Dom.id "guild_openDm_0")
                    , admin.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.text "started a call", Test.Html.Selector.text "Call ended" ])
                    , admin.click 100 (Dom.id "guild_voiceChat")
                    , admin.click 100 (Dom.id "guild_startVoiceChat")
                    , user.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.text "started a call", Test.Html.Selector.text "Call ended" ])
                    ]
                )
            ]
        ]


checkNoNotification : String -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
checkNoNotification body =
    T.checkState
        100
        (\data ->
            case
                List.filter
                    (\request ->
                        case request.body of
                            T.JsonBody json ->
                                case Codec.decodeValue Broadcast.pushNotificationCodec json of
                                    Ok pushNotification ->
                                        (pushNotification.body == body)
                                            && (request.url == "http://localhost:3000/file/internal/push-notification")

                                    Err _ ->
                                        False

                            _ ->
                                False
                    )
                    data.httpRequests
            of
                _ :: _ ->
                    Err ("Notification found for \"" ++ body ++ "\"")

                [] ->
                    Ok ()
        )


dropPrefix : String -> String -> String
dropPrefix prefix text =
    if String.startsWith prefix text then
        String.dropLeft (String.length prefix) text

    else
        text


connectTwoUsersAndJoinNewGuild :
    { width : Int, height : Int }
    ->
        (T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         -> T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         -> List (T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
        )
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
connectTwoUsersAndJoinNewGuild windowSize continueFunc =
    T.connectFrontend
        100
        sessionId0
        "/"
        windowSize
        (\admin ->
            [ handleLogin firefoxDesktop adminEmail admin
            , admin.click 100 (Dom.id "guild_createGuild")
            , admin.input 100 (Dom.id "newGuildName") "My new guild!"
            , admin.click 100 (Dom.id "guild_createGuildSubmit")
            , admin.click 100 (Dom.id "guild_inviteLinkCreatorRoute")
            , admin.click 100 (Dom.id "guild_createInviteLink")
            , admin.click 100 (Dom.id "guild_copyText")
            , T.andThen
                100
                (\data ->
                    case
                        List.Extra.findMap
                            (\request ->
                                if request.clientId == admin.clientId && request.portName == "copy_to_clipboard_to_js" then
                                    Json.Decode.decodeValue Json.Decode.string request.value |> Result.toMaybe

                                else
                                    Nothing
                            )
                            data.portRequests
                    of
                        Just text ->
                            [ T.connectFrontend
                                100
                                sessionId1
                                (dropPrefix Env.domain text)
                                windowSize
                                (\user ->
                                    [ user.portEvent 10 "user_agent_from_js" (Json.Encode.string firefoxDesktop)
                                    , handleLoginFromLoginPage userEmail user
                                    , user.input 100 (Dom.id "loginForm_name") "Stevie Steve"
                                    , user.click 100 (Dom.id "loginForm_submit")
                                    , user.click 100 (Dom.id "guild_openChannel_0")
                                    , enableNotifications False user
                                    , checkNotification "Push notifications enabled"
                                    , admin.click 100 (Dom.id "guild_openChannel_0")
                                    , T.group (continueFunc admin user)
                                    ]
                                )
                            ]

                        Nothing ->
                            [ T.checkState 0 (\_ -> Err "Clipboard text not found") ]
                )
            ]
        )


focusEvent :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> DelayInMs
    -> Maybe HtmlId
    -> Maybe Range
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
focusEvent user delayInMs maybeHtmlId maybeSelection =
    user.portEvent
        delayInMs
        "focus_changed_from_js"
        (( "id"
         , case maybeHtmlId of
            Just htmlId ->
                Json.Encode.string (Dom.idToString htmlId)

            Nothing ->
                Json.Encode.null
         )
            :: (case maybeSelection of
                    Just { start, end } ->
                        [ ( "selectionStart", Json.Encode.int start ), ( "selectionEnd", Json.Encode.int end ) ]

                    Nothing ->
                        []
               )
            |> Json.Encode.object
        )


writeMessage : T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel -> DelayInMs -> String -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
writeMessage user delayInMs text =
    T.group
        [ focusEvent user delayInMs (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
        , user.click 100 (Dom.id "channel_textinput")
        , user.input 100 (Dom.id "channel_textinput") text
        , user.keyDown 100 (Dom.id "channel_textinput") "Enter" []
        , focusEvent user 100 Nothing Nothing
        ]


writeMessageMobile : T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel -> String -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
writeMessageMobile user text =
    T.group
        [ user.input 100 (Dom.id "channel_textinput") text
        , user.click 100 (Dom.id "messageMenu_channelInput_sendMessage")
        ]


createThread : T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel -> Id ChannelMessageId -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
createThread user messageId =
    T.group
        [ user.mouseEnter 100 (Dom.id ("guild_message_" ++ Id.toString messageId)) ( 10, 10 ) []
        , user.custom
            100
            (Dom.id "miniView_showFullMenu")
            "click"
            (Json.Encode.object
                [ ( "clientX", Json.Encode.int 500 )
                , ( "clientY", Json.Encode.int 300 )
                ]
            )
        , user.click 100 (Dom.id "messageMenu_openThread")
        ]


clickSpoiler :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> HtmlId
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
clickSpoiler user htmlId =
    T.group
        [ user.click 100 htmlId
        , user.checkView
            100
            (Test.Html.Query.hasNot [ Test.Html.Selector.attribute (Html.Attributes.id (Dom.idToString htmlId)) ])
        ]


scrollToTop :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
scrollToTop user =
    user.custom
        100
        Pages.Guild.conversationContainerId
        "scroll"
        (Json.Encode.object
            [ ( "target"
              , Json.Encode.object
                    [ ( "scrollTop", Json.Encode.float 10 )
                    , ( "scrollHeight", Json.Encode.float 1000 )
                    , ( "clientHeight", Json.Encode.float (desktopWindow.height - 40) )
                    ]
              )
            ]
        )


scrollToMiddle :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
scrollToMiddle user =
    user.custom
        100
        Pages.Guild.conversationContainerId
        "scroll"
        (Json.Encode.object
            [ ( "target"
              , Json.Encode.object
                    [ ( "scrollTop", Json.Encode.float 1000 )
                    , ( "scrollHeight", Json.Encode.float 2000 )
                    , ( "clientHeight", Json.Encode.float (desktopWindow.height - 40) )
                    ]
              )
            ]
        )


hasExactText :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> List String
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
hasExactText user texts =
    user.checkView 100 (Test.Html.Query.has (List.map Test.Html.Selector.exactText texts))


hasText :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> List String
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
hasText user texts =
    user.checkView 100 (Test.Html.Query.has (List.map Test.Html.Selector.text texts))


hasNotExactText :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> List String
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
hasNotExactText user texts =
    user.checkView 100 (Test.Html.Query.hasNot (List.map Test.Html.Selector.exactText texts))


hasNotText :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> List String
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
hasNotText user texts =
    user.checkView 100 (Test.Html.Query.hasNot (List.map Test.Html.Selector.text texts))


noMissingMessages : DelayInMs -> T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
noMissingMessages delayInMs user =
    user.checkView
        delayInMs
        (Test.Html.Query.hasNot
            [ Test.Html.Selector.text "Something went wrong when loading message" ]
        )


firefoxDesktop : String
firefoxDesktop =
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0"


chromeDesktop : String
chromeDesktop =
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"


safariIphone : String
safariIphone =
    "Mozilla/5.0 (iPhone; CPU iPhone OS 13_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.1 Mobile/15E148 Safari/604.1"


andThenWebsocket :
    (Websocket.Connection
     -> T.WebsocketState
     -> List (T.Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    )
    -> T.Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
andThenWebsocket andThenFunc =
    T.andThen
        120
        (\data ->
            let
                maybeConnection : List ( Websocket.Connection, T.WebsocketState )
                maybeConnection =
                    SeqDict.toList data.websockets
                        |> List.filterMap
                            (\( ( requestedBy, connection ), websocketState ) ->
                                if (requestedBy == RequestedByBackend) && (websocketState.closedAt == Nothing) then
                                    Just ( connection, websocketState )

                                else
                                    Nothing
                            )
            in
            case maybeConnection of
                [ ( connection, websocketState ) ] ->
                    andThenFunc connection websocketState

                [] ->
                    [ T.checkState 0 (\_ -> Err "Didn't find any websocket connection") ]

                _ ->
                    [ T.checkState 0 (\_ -> Err "Found multiple websocket connections. I don't know which one to use.") ]
        )


isOp2 : { data : String, sentAt : Time.Posix } -> Bool
isOp2 data =
    case Json.Decode.decodeString (Json.Decode.field "op" Json.Decode.int) data.data of
        Ok 2 ->
            True

        _ ->
            False


decodeOp2Token : Json.Decode.Decoder String
decodeOp2Token =
    Json.Decode.field "op" Json.Decode.int
        |> Json.Decode.andThen
            (\op ->
                if op == 2 then
                    Json.Decode.at [ "d", "token" ] Json.Decode.string

                else
                    Json.Decode.fail "not op 2"
            )


websocketByDiscordToken :
    String
    -> T.Data frontendModel backendModel
    -> Maybe ( Websocket.Connection, T.WebsocketState )
websocketByDiscordToken token data =
    SeqDict.toList data.websockets
        |> List.filterMap
            (\( ( requestedBy, connection ), websocketState ) ->
                if requestedBy == RequestedByBackend && websocketState.closedAt == Nothing then
                    let
                        sentTokens : List String
                        sentTokens =
                            Array.toList websocketState.dataSent
                                |> List.filterMap
                                    (\msg ->
                                        Json.Decode.decodeString decodeOp2Token msg.data
                                            |> Result.toMaybe
                                    )
                    in
                    if List.member token sentTokens then
                        Just ( connection, websocketState )

                    else
                        Nothing

                else
                    Nothing
            )
        |> List.head


discordUserAuth : Discord.UserAuth
discordUserAuth =
    { token = "legit-token"
    , userAgent = "Mozilla/5.0 (X11; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0"
    , xSuperProperties =
        JsonObject
            (Dict.fromList
                [ ( "browser", JsonString "Firefox" )
                , ( "browser_user_agent", JsonString "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:143.0) Gecko/20100101 Firefox/143.0" )
                , ( "browser_version", JsonString "143.0" )
                , ( "client_app_state", JsonString "unfocused" )
                , ( "client_build_number", JsonNumber 453248 )
                , ( "client_event_source", JsonNull )
                , ( "client_heartbeat_session_id", JsonString "1a49edbe-0c97-4445-996f-5cc93d84bbae" )
                , ( "client_launch_id", JsonString "1b1343e7-e590-4b53-9d1b-b929fdd42419" )
                , ( "device", JsonString "" )
                , ( "has_client_mods", JsonBool False )
                , ( "launch_signature", JsonString "1c0ef792-b757-44e8-ba1f-332929609d08" )
                , ( "os", JsonString "Linux" )
                , ( "os_version", JsonString "" )
                , ( "referrer", JsonString "https://www.google.com/" )
                , ( "referrer_current", JsonString "" )
                , ( "referring_domain", JsonString "www.google.com" )
                , ( "referring_domain_current", JsonString "" )
                , ( "release_channel", JsonString "stable" )
                , ( "search_engine", JsonString "google" )
                , ( "system_locale", JsonString "en-US" )
                ]
            )
    }


imageViewerTests :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
imageViewerTests imageUploadConfig =
    T.testGroup
        "Image viewer"
        [ startTest
            "Clicking an image attachment opens a zoomable image viewer overlay"
            startTime
            imageUploadConfig
            [ connectTwoUsersAndJoinNewGuild
                desktopWindow
                (\admin _ ->
                    [ -- Attach an image to the message, wait for the upload to
                      -- finish, then send the message.
                      admin.click 100 (Dom.id "messageMenu_channelInput_uploadFile")
                    , focusEvent admin 1000 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                    , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                    , admin.checkView
                        0
                        (Test.Html.Query.has [ Test.Html.Selector.id "spoiler_1_image_1" ])

                    -- Clicking the image opens the overlay instead of a new tab. Once
                    -- the overlay is open it is independent of the message, so it
                    -- stays open as the rest of the app keeps rendering.
                    , admin.click 0 (Dom.id "spoiler_1_image_1")
                    , admin.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.id "imageViewer_close" ])
                    , admin.snapshotView 100 { name = "Image viewer overlay" }

                    -- The image can be dragged around.
                    , admin.mouseDown 100 (Dom.id "imageViewer_overlay") ( 100, 100 ) []
                    , admin.mouseMove 100 (Dom.id "imageViewer_overlay") ( 250, 180 ) []
                    , admin.mouseUp 100 (Dom.id "imageViewer_overlay") ( 250, 180 ) []
                    , T.checkState
                        100
                        (\data ->
                            if
                                List.any
                                    (\( _, frontend ) ->
                                        case frontend of
                                            Types.Loaded loaded ->
                                                case loaded.imageViewer of
                                                    Just imageViewer ->
                                                        imageViewer.offsetX == 150 && imageViewer.offsetY == 80

                                                    Nothing ->
                                                        False

                                            Types.Loading _ ->
                                                False
                                    )
                                    (SeqDict.toList data.frontends)
                            then
                                Ok ()

                            else
                                Err "Dragging the image should have moved it by (150, 80)"
                        )

                    -- Scroll-zoom glides toward its target rather than snapping: a
                    -- frame or two after the wheel event the scale is partway between
                    -- 1 and 1.1.
                    , admin.wheel 100 (Dom.id "imageViewer_overlay") -1 ( 700, 400 ) [] []
                    , T.checkState
                        50
                        (\data ->
                            if
                                List.any
                                    (\( _, frontend ) ->
                                        case frontend of
                                            Types.Loaded loaded ->
                                                case loaded.imageViewer of
                                                    Just imageViewer ->
                                                        imageViewer.scale > 1.0 && imageViewer.scale < 1.1

                                                    Nothing ->
                                                        False

                                            Types.Loading _ ->
                                                False
                                    )
                                    (SeqDict.toList data.frontends)
                            then
                                Ok ()

                            else
                                Err "Scroll-zoom should glide toward its target (zoom inertia)"
                        )

                    -- Once it settles, the zoom anchors on the cursor: zooming in at
                    -- (700, 400), down and to the right of the 1000x600 viewport
                    -- center, shifts the image so that point stays under the cursor.
                    -- From offset (150, 80) and scale 1, scrolling in by 1.1x gives
                    -- offsetX = 200*(1-1.1) + 1.1*150 = 145 and offsetY = 100*(1-1.1) + 1.1*80 = 78.
                    , T.checkState
                        2000
                        (\data ->
                            if
                                List.any
                                    (\( _, frontend ) ->
                                        case frontend of
                                            Types.Loaded loaded ->
                                                case loaded.imageViewer of
                                                    Just imageViewer ->
                                                        (abs (imageViewer.scale - 1.1) < 0.01)
                                                            && (abs (imageViewer.offsetX - 145) < 0.01)
                                                            && (abs (imageViewer.offsetY - 78) < 0.01)

                                                    Nothing ->
                                                        False

                                            Types.Loading _ ->
                                                False
                                    )
                                    (SeqDict.toList data.frontends)
                            then
                                Ok ()

                            else
                                Err "Scroll-zooming should settle anchored on the cursor"
                        )

                    -- Zooming in keeps the overlay open.
                    , admin.click 100 (Dom.id "imageViewer_zoomIn")
                    , admin.click 100 (Dom.id "imageViewer_zoomIn")
                    , admin.snapshotView 2000 { name = "Image viewer overlay zoomed in" }

                    -- The x button closes the overlay.
                    , admin.click 100 (Dom.id "imageViewer_close")
                    , admin.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.id "imageViewer_close" ])
                    ]
                )
            ]
        , startTest
            "On mobile the image viewer has no buttons and uses pinch/drag gestures"
            startTime
            imageUploadConfig
            [ connectTwoUsersAndJoinNewGuild
                mobileWindow
                (\admin _ ->
                    let
                        touchEvent : List ( Float, Float ) -> { changedTouches : List { id : Int, clientPos : ( Float, Float ), pagePos : ( Float, Float ), screenPos : ( Float, Float ) }, targetTouches : List { id : Int, clientPos : ( Float, Float ), pagePos : ( Float, Float ), screenPos : ( Float, Float ) } }
                        touchEvent points =
                            { changedTouches = []
                            , targetTouches =
                                List.indexedMap
                                    (\index ( x, y ) ->
                                        { id = index, clientPos = ( x, y ), pagePos = ( x, y ), screenPos = ( x, y ) }
                                    )
                                    points
                            }
                    in
                    [ -- Attach an image and send the message.
                      admin.click 100 (Dom.id "messageMenu_channelInput_uploadFile")
                    , admin.click 1000 (Dom.id "messageMenu_channelInput_sendMessage")
                    , admin.checkView
                        0
                        (Test.Html.Query.has [ Test.Html.Selector.id "spoiler_1_image_1" ])

                    -- Tapping the image opens the overlay.
                    , admin.click 0 (Dom.id "spoiler_1_image_1")
                    , admin.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.id "imageViewer_overlay" ])

                    -- On mobile the zoom and close buttons are hidden.
                    , admin.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.id "imageViewer_close" ])
                    , admin.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.id "imageViewer_zoomIn" ])
                    , admin.snapshotView 100 { name = "Image viewer overlay on mobile" }

                    -- Pinching with two fingers zooms in (distance goes 20 -> 100, so
                    -- the scale becomes 5x) anchored on the pinch midpoint (300, 400).
                    -- That midpoint is to the right of the 400x800 viewport center, so
                    -- the image shifts left: offsetX = 100*(1-5) + 5*0 = -400.
                    , admin.touchStart 100 (Dom.id "imageViewer_overlay") (touchEvent [ ( 290, 400 ), ( 310, 400 ) ])
                    , admin.touchMove 100 (Dom.id "imageViewer_overlay") (touchEvent [ ( 250, 400 ), ( 350, 400 ) ])
                    , T.checkState
                        100
                        (\data ->
                            if
                                List.any
                                    (\( _, frontend ) ->
                                        case frontend of
                                            Types.Loaded loaded ->
                                                case loaded.imageViewer of
                                                    Just imageViewer ->
                                                        (imageViewer.scale == 5)
                                                            && (imageViewer.offsetX == -400)
                                                            && (imageViewer.offsetY == 0)

                                                    Nothing ->
                                                        False

                                            Types.Loading _ ->
                                                False
                                    )
                                    (SeqDict.toList data.frontends)
                            then
                                Ok ()

                            else
                                Err "Pinching apart should zoom to 5x anchored on the pinch midpoint"
                        )
                    , admin.touchEnd 100 (Dom.id "imageViewer_overlay") (touchEvent [])

                    -- Dragging the image off the top of the screen dismisses it.
                    , admin.touchStart 100 (Dom.id "imageViewer_overlay") (touchEvent [ ( 200, 400 ) ])
                    , admin.touchMove 100 (Dom.id "imageViewer_overlay") (touchEvent [ ( 200, -3000 ) ])
                    , admin.touchEnd 100 (Dom.id "imageViewer_overlay") (touchEvent [])
                    , admin.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.id "imageViewer_overlay" ])
                    ]
                )
            ]
        , startTest
            "Moving both fingers together pans the image while pinching"
            startTime
            imageUploadConfig
            [ connectTwoUsersAndJoinNewGuild
                mobileWindow
                (\admin _ ->
                    let
                        touchEvent : List ( Float, Float ) -> { changedTouches : List { id : Int, clientPos : ( Float, Float ), pagePos : ( Float, Float ), screenPos : ( Float, Float ) }, targetTouches : List { id : Int, clientPos : ( Float, Float ), pagePos : ( Float, Float ), screenPos : ( Float, Float ) } }
                        touchEvent points =
                            { changedTouches = []
                            , targetTouches =
                                List.indexedMap
                                    (\index ( x, y ) ->
                                        { id = index, clientPos = ( x, y ), pagePos = ( x, y ), screenPos = ( x, y ) }
                                    )
                                    points
                            }
                    in
                    [ admin.click 100 (Dom.id "messageMenu_channelInput_uploadFile")
                    , admin.click 1000 (Dom.id "messageMenu_channelInput_sendMessage")
                    , admin.checkView 0 (Test.Html.Query.has [ Test.Html.Selector.id "spoiler_1_image_1" ])
                    , admin.click 0 (Dom.id "spoiler_1_image_1")
                    , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "imageViewer_overlay" ])

                    -- Two fingers a constant 20px apart, with their midpoint
                    -- sliding from (200, 400) to (300, 500). The distance doesn't
                    -- change, so there's no zoom (scale stays 1); the image just
                    -- pans by the (100, 100) the midpoint moved.
                    , admin.touchStart 100 (Dom.id "imageViewer_overlay") (touchEvent [ ( 190, 400 ), ( 210, 400 ) ])
                    , admin.touchMove 100 (Dom.id "imageViewer_overlay") (touchEvent [ ( 290, 500 ), ( 310, 500 ) ])
                    , T.checkState
                        100
                        (\data ->
                            if
                                List.any
                                    (\( _, frontend ) ->
                                        case frontend of
                                            Types.Loaded loaded ->
                                                case loaded.imageViewer of
                                                    Just imageViewer ->
                                                        (imageViewer.scale == 1)
                                                            && (imageViewer.offsetX == 100)
                                                            && (imageViewer.offsetY == 100)

                                                    Nothing ->
                                                        False

                                            Types.Loading _ ->
                                                False
                                    )
                                    (SeqDict.toList data.frontends)
                            then
                                Ok ()

                            else
                                Err "Moving both fingers together should pan the image by the midpoint delta without zooming"
                        )
                    , admin.touchEnd 100 (Dom.id "imageViewer_overlay") (touchEvent [])
                    ]
                )
            ]
        , startTest
            "Flinging the image in the viewer keeps it moving (inertia)"
            startTime
            imageUploadConfig
            [ connectTwoUsersAndJoinNewGuild
                desktopWindow
                (\admin _ ->
                    [ admin.click 100 (Dom.id "messageMenu_channelInput_uploadFile")
                    , focusEvent admin 1000 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                    , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                    , admin.checkView 0 (Test.Html.Query.has [ Test.Html.Selector.id "spoiler_1_image_1" ])
                    , admin.click 0 (Dom.id "spoiler_1_image_1")
                    , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "imageViewer_overlay" ])

                    -- Flick: move by (20, 10) and release on the same frame (delay 0)
                    -- so the velocity is preserved as momentum.
                    , admin.mouseDown 100 (Dom.id "imageViewer_overlay") ( 500, 300 ) []
                    , admin.mouseMove 100 (Dom.id "imageViewer_overlay") ( 520, 310 ) []
                    , admin.mouseUp 0 (Dom.id "imageViewer_overlay") ( 520, 310 ) []

                    -- Right after release the image has only moved by the drag amount.
                    , T.checkState
                        0
                        (\data ->
                            if
                                List.any
                                    (\( _, frontend ) ->
                                        case frontend of
                                            Types.Loaded loaded ->
                                                case loaded.imageViewer of
                                                    Just imageViewer ->
                                                        imageViewer.offsetX == 20 && imageViewer.offsetY == 10

                                                    Nothing ->
                                                        False

                                            Types.Loading _ ->
                                                False
                                    )
                                    (SeqDict.toList data.frontends)
                            then
                                Ok ()

                            else
                                Err "Right after the flick the image should have moved by exactly the drag amount"
                        )

                    -- After the momentum settles the image has coasted much further in
                    -- the same direction, but stayed on screen.
                    , T.checkState
                        2000
                        (\data ->
                            if
                                List.any
                                    (\( _, frontend ) ->
                                        case frontend of
                                            Types.Loaded loaded ->
                                                case loaded.imageViewer of
                                                    Just imageViewer ->
                                                        (imageViewer.offsetX > 100)
                                                            && (imageViewer.offsetX < 400)
                                                            && (imageViewer.offsetY > 50)
                                                            && (imageViewer.offsetY < 300)

                                                    Nothing ->
                                                        False

                                            Types.Loading _ ->
                                                False
                                    )
                                    (SeqDict.toList data.frontends)
                            then
                                Ok ()

                            else
                                Err "Momentum should have coasted the image further after release"
                        )
                    , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "imageViewer_overlay" ])
                    ]
                )
            ]
        , startTest
            "The image viewer background fades as the image is dragged off screen"
            startTime
            imageUploadConfig
            [ connectTwoUsersAndJoinNewGuild
                desktopWindow
                (\admin _ ->
                    [ admin.click 100 (Dom.id "messageMenu_channelInput_uploadFile")
                    , focusEvent admin 1000 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                    , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                    , admin.checkView 0 (Test.Html.Query.has [ Test.Html.Selector.id "spoiler_1_image_1" ])
                    , admin.click 0 (Dom.id "spoiler_1_image_1")
                    , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "imageViewer_overlay" ])

                    -- Drag the image until its center sits in the bottom-right corner
                    -- of the 1000x600 window, leaving only its top-left quarter (25%
                    -- of the area) visible, so the black background is half faded.
                    , admin.mouseDown 50 (Dom.id "imageViewer_overlay") ( 100, 100 ) []
                    , admin.mouseMove 50 (Dom.id "imageViewer_overlay") ( 200, 200 ) []
                    , admin.mouseUp 50 (Dom.id "imageViewer_overlay") ( 200, 200 ) []

                    -- Image is mostly on screen so doesn't get removed
                    , admin.checkView 1000 (Test.Html.Query.has [ Test.Html.Selector.id "imageViewer_overlay" ])
                    , admin.mouseDown 50 (Dom.id "imageViewer_overlay") ( 200, 200 ) []
                    , admin.mouseMove 50 (Dom.id "imageViewer_overlay") ( 350, 350 ) []
                    , admin.mouseUp 50 (Dom.id "imageViewer_overlay") ( 350, 350 ) []
                    , admin.snapshotView 30 { name = "Image viewer background faded" }
                    , admin.checkView 1000 (Test.Html.Query.hasNot [ Test.Html.Selector.id "imageViewer_overlay" ])
                    ]
                )
            ]
        , startTest
            "Right clicking images and links adds copy options to the message menu"
            startTime
            imageUploadConfig
            [ connectTwoUsersAndJoinNewGuild
                desktopWindow
                (\admin _ ->
                    let
                        imageUrl : String
                        imageUrl =
                            Env.domain ++ "/file/1/123123123"

                        linkUrl : String
                        linkUrl =
                            "https://example.com/some-page"
                    in
                    [ -- Attach an image to the message and send it.
                      admin.click 100 (Dom.id "messageMenu_channelInput_uploadFile")
                    , focusEvent admin 1000 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                    , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                    , admin.checkView
                        0
                        (Test.Html.Query.has [ Test.Html.Selector.id "spoiler_1_image_1" ])

                    -- Right clicking somewhere on the message that isn't an image opens
                    -- the message menu without the image specific options.
                    , admin.custom
                        100
                        (Dom.id "guild_message_1")
                        "contextmenu"
                        (Json.Encode.object
                            [ ( "clientX", Json.Encode.float 50 )
                            , ( "clientY", Json.Encode.float 150 )
                            ]
                        )
                    , admin.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.id "messageMenu_copyImage" ])

                    -- Right clicking the image itself includes its full-size url (exposed
                    -- via the data-image-url attribute) so the menu offers the image
                    -- specific copy options.
                    , admin.custom
                        100
                        (Dom.id "guild_message_1")
                        "contextmenu"
                        (Json.Encode.object
                            [ ( "clientX", Json.Encode.float 50 )
                            , ( "clientY", Json.Encode.float 150 )
                            , ( "target"
                              , Json.Encode.object
                                    [ ( "dataset"
                                      , Json.Encode.object [ ( "imageUrl", Json.Encode.string imageUrl ) ]
                                      )
                                    ]
                              )
                            ]
                        )
                    , admin.checkView
                        100
                        (Test.Html.Query.has
                            [ Test.Html.Selector.id "messageMenu_copyImage" ]
                        )
                    , admin.checkView
                        100
                        (Test.Html.Query.has
                            [ Test.Html.Selector.id "messageMenu_copyImageLink" ]
                        )
                    , admin.snapshotView 100 { name = "Message menu with copy image options" }

                    -- "Copy image" copies the actual image data to the clipboard.
                    , admin.click 100 (Dom.id "messageMenu_copyImage")
                    , T.andThen
                        100
                        (\data ->
                            case
                                List.Extra.findMap
                                    (\request ->
                                        if request.clientId == admin.clientId && request.portName == "copy_image_to_clipboard_to_js" then
                                            Json.Decode.decodeValue Json.Decode.string request.value |> Result.toMaybe

                                        else
                                            Nothing
                                    )
                                    data.portRequests
                            of
                                Just copiedUrl ->
                                    if copiedUrl == imageUrl then
                                        []

                                    else
                                        [ T.checkState 0 (\_ -> Err ("Copy image copied the wrong url: " ++ copiedUrl)) ]

                                Nothing ->
                                    [ T.checkState 0 (\_ -> Err "Copy image should have triggered the copy_image_to_clipboard_to_js port") ]
                        )

                    -- "Copy image link" copies the image's url as text instead.
                    , admin.click 100 (Dom.id "messageMenu_copyImageLink")
                    , T.andThen
                        100
                        (\data ->
                            case
                                List.Extra.findMap
                                    (\request ->
                                        if request.clientId == admin.clientId && request.portName == "copy_to_clipboard_to_js" then
                                            Json.Decode.decodeValue Json.Decode.string request.value |> Result.toMaybe

                                        else
                                            Nothing
                                    )
                                    data.portRequests
                            of
                                Just copiedUrl ->
                                    if copiedUrl == imageUrl then
                                        []

                                    else
                                        [ T.checkState 0 (\_ -> Err ("Copy image link copied the wrong url: " ++ copiedUrl)) ]

                                Nothing ->
                                    [ T.checkState 0 (\_ -> Err "Copy image link should have triggered the copy_to_clipboard_to_js port") ]
                        )

                    -- The element under the cursor is often a descendant of the one
                    -- carrying data-image-url (e.g. the <canvas>/<img> that an animated
                    -- gif player appends inside itself). The menu still finds the url by
                    -- walking up to the ancestor that has it.
                    , admin.custom
                        100
                        (Dom.id "guild_message_1")
                        "contextmenu"
                        (Json.Encode.object
                            [ ( "clientX", Json.Encode.float 50 )
                            , ( "clientY", Json.Encode.float 150 )
                            , ( "target"
                              , Json.Encode.object
                                    [ ( "dataset", Json.Encode.object [] )
                                    , ( "parentElement"
                                      , Json.Encode.object
                                            [ ( "dataset"
                                              , Json.Encode.object [ ( "imageUrl", Json.Encode.string imageUrl ) ]
                                              )
                                            ]
                                      )
                                    ]
                              )
                            ]
                        )
                    , admin.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.id "messageMenu_copyImageLink" ])

                    -- Right clicking a hyperlink offers a "Copy link" option (and not the
                    -- image options) that copies the link's url.
                    , admin.custom
                        100
                        (Dom.id "guild_message_1")
                        "contextmenu"
                        (Json.Encode.object
                            [ ( "clientX", Json.Encode.float 50 )
                            , ( "clientY", Json.Encode.float 150 )
                            , ( "target"
                              , Json.Encode.object
                                    [ ( "dataset"
                                      , Json.Encode.object [ ( "linkUrl", Json.Encode.string linkUrl ) ]
                                      )
                                    ]
                              )
                            ]
                        )
                    , admin.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.id "messageMenu_copyLink" ])
                    , admin.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.id "messageMenu_copyImage" ])
                    , admin.click 100 (Dom.id "messageMenu_copyLink")
                    , T.andThen
                        100
                        (\data ->
                            if
                                List.any
                                    (\request ->
                                        (request.clientId == admin.clientId)
                                            && (request.portName == "copy_to_clipboard_to_js")
                                            && (Json.Decode.decodeValue Json.Decode.string request.value == Ok linkUrl)
                                    )
                                    data.portRequests
                            then
                                []

                            else
                                [ T.checkState 0 (\_ -> Err "Copy link should have copied the link url to the clipboard") ]
                        )
                    ]
                )
            ]
        , startTest
            "Long pressing images and links adds copy options to the mobile message menu"
            startTime
            imageUploadConfig
            [ connectTwoUsersAndJoinNewGuild
                mobileWindow
                (\admin _ ->
                    let
                        imageUrl : String
                        imageUrl =
                            Env.domain ++ "/file/1/123123123"

                        linkUrl : String
                        linkUrl =
                            "https://example.com/some-page"

                        -- A "touchstart" event whose target carries the given data-*
                        -- attributes, in the shape our Touch decoder expects (touches is
                        -- a TouchList-like object with a length and numeric indices).
                        longPress : List ( String, Json.Encode.Value ) -> Json.Encode.Value
                        longPress dataset =
                            Json.Encode.object
                                [ ( "timeStamp", Json.Encode.float 1000 )
                                , ( "touches"
                                  , Json.Encode.object
                                        [ ( "length", Json.Encode.int 1 )
                                        , ( "0"
                                          , Json.Encode.object
                                                [ ( "identifier", Json.Encode.int 0 )
                                                , ( "clientX", Json.Encode.float 50 )
                                                , ( "clientY", Json.Encode.float 150 )
                                                , ( "target"
                                                  , Json.Encode.object [ ( "id", Json.Encode.string "guild_message_1" ) ]
                                                  )
                                                ]
                                          )
                                        ]
                                  )
                                , ( "target", Json.Encode.object [ ( "dataset", Json.Encode.object dataset ) ] )
                                ]

                        -- Releasing the touch resets the drag state so the next long press
                        -- can be registered.
                        touchEnd : Json.Encode.Value
                        touchEnd =
                            Json.Encode.object [ ( "timeStamp", Json.Encode.float 2000 ) ]
                    in
                    [ -- Attach an image and send the message.
                      admin.click 100 (Dom.id "messageMenu_channelInput_uploadFile")
                    , admin.click 1000 (Dom.id "messageMenu_channelInput_sendMessage")
                    , admin.checkView
                        0
                        (Test.Html.Query.has [ Test.Html.Selector.id "spoiler_1_image_1" ])

                    -- Long pressing the image opens the mobile menu. The url is found on
                    -- the touched element, so the menu offers the image copy options.
                    -- (500ms after touchstart the long-press timer fires.)
                    , admin.custom
                        100
                        (Dom.id "guild_message_1")
                        "touchstart"
                        (longPress [ ( "imageUrl", Json.Encode.string imageUrl ) ])
                    , admin.checkView
                        600
                        (Test.Html.Query.has [ Test.Html.Selector.id "messageMenu_copyImage" ])
                    , admin.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.id "messageMenu_copyImageLink" ])
                    , admin.snapshotView 100 { name = "Mobile message menu with copy image options" }
                    , admin.click 100 (Dom.id "messageMenu_copyImageLink")
                    , T.andThen
                        100
                        (\data ->
                            if
                                List.any
                                    (\request ->
                                        (request.clientId == admin.clientId)
                                            && (request.portName == "copy_to_clipboard_to_js")
                                            && (Json.Decode.decodeValue Json.Decode.string request.value == Ok imageUrl)
                                    )
                                    data.portRequests
                            then
                                []

                            else
                                [ T.checkState 0 (\_ -> Err "Copy image link should have copied the image url to the clipboard") ]
                        )

                    -- Release the touch, then long press a hyperlink instead.
                    , admin.custom 100 (Dom.id "elm-ui-root-id") "touchend" touchEnd
                    , admin.custom
                        100
                        (Dom.id "guild_message_1")
                        "touchstart"
                        (longPress [ ( "linkUrl", Json.Encode.string linkUrl ) ])
                    , admin.checkView
                        600
                        (Test.Html.Query.has [ Test.Html.Selector.id "messageMenu_copyLink" ])
                    , admin.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.id "messageMenu_copyImage" ])
                    , admin.click 100 (Dom.id "messageMenu_copyLink")
                    , T.andThen
                        100
                        (\data ->
                            if
                                List.any
                                    (\request ->
                                        (request.clientId == admin.clientId)
                                            && (request.portName == "copy_to_clipboard_to_js")
                                            && (Json.Decode.decodeValue Json.Decode.string request.value == Ok linkUrl)
                                    )
                                    data.portRequests
                            then
                                []

                            else
                                [ T.checkState 0 (\_ -> Err "Copy link should have copied the link url to the clipboard") ]
                        )
                    ]
                )
            ]
        ]


tallSnapshot :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> DelayInMs
    -> { name : String }
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
tallSnapshot user delayInMs name =
    T.andThen
        0
        (\data ->
            case SeqDict.get user.clientId data.frontends of
                Just frontend ->
                    let
                        windowSize : Coord CssPixels
                        windowSize =
                            case frontend of
                                Types.Loading loading ->
                                    loading.windowSize

                                Types.Loaded loaded ->
                                    loaded.windowSize
                    in
                    [ user.resizeWindow delayInMs { width = Coord.xRaw windowSize, height = 2000 }
                    , user.snapshotView 50 name
                    , user.resizeWindow delayInMs { width = Coord.xRaw windowSize, height = Coord.yRaw windowSize }
                    ]

                Nothing ->
                    [ user.checkModel 0 (\_ -> Err "Couldn't get window size in order to do a snapshot") ]
        )


linkDiscordUrl : String
linkDiscordUrl =
    "/link-discord/?data=" ++ Codec.encodeToString 0 User.linkDiscordDataCodec discordUserAuth


linkDiscordAndLogin :
    SessionId
    -> String
    -> EmailAddress
    -> Bool
    -> String
    -> String
    -> (T.FrontendActions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> List (T.Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel))
    -> T.Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
linkDiscordAndLogin sessionId name emailAddress isNewAccount discordOp0Ready discordOp0ReadySupplemental continueWith =
    T.connectFrontend
        100
        sessionId
        ("/link-discord/?data=" ++ Codec.encodeToString 0 User.linkDiscordDataCodec discordUserAuth)
        desktopWindow
        (\userA ->
            [ userA.portEvent 10 "user_agent_from_js" (Json.Encode.string firefoxDesktop)
            , handleLoginFromLoginPage emailAddress userA
            , if isNewAccount then
                T.group
                    [ userA.input 100 (Dom.id "loginForm_name") name
                    , userA.click 100 (Dom.id "loginForm_submit")
                    ]

              else
                T.group []
            , andThenWebsocket
                (\connection _ ->
                    [ T.websocketSendString 100 connection """{"t":null,"s":null,"op":10,"d":{"heartbeat_interval":41250,"_trace":["[\\"gateway-prd-arm-us-east1-d-swb5\\",{\\"micros\\":0.0}]"]}}""" ]
                )
            , andThenWebsocket
                (\connection websocketState ->
                    case Array.toList websocketState.dataSent |> List.filter isOp2 of
                        [ _ ] ->
                            [ T.websocketSendString 100 connection discordOp0Ready
                            , T.websocketSendString 100 connection discordOp0ReadySupplemental
                            ]

                        _ ->
                            [ T.checkState 0 (\_ -> Err "Wrong number of Discord connections made") ]
                )
            , userA.checkView
                100
                (Test.Html.Query.has
                    [ Test.Html.Selector.exactText name
                    , Test.Html.Selector.exactText "at0232"
                    , Test.Html.Selector.exactText "kess"
                    , Test.Html.Selector.exactText "purplelite"
                    , Test.Html.Selector.exactText "BT"
                    ]
                )
            , T.group (continueWith userA)
            ]
        )


{-| Links a second Discord account to the currently logged in user, using a
different token and user id than the first link. The resulting Discord account
will appear as a member of the same guilds as the first account because the
provided ready data is reused with the user id substituted.
-}
linkSecondDiscordAccount :
    SessionId
    -> String
    -> String
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
linkSecondDiscordAccount sessionId discordOp0Ready discordOp0ReadySupplemental =
    let
        secondAuth : Discord.UserAuth
        secondAuth =
            { discordUserAuth | token = secondDiscordToken }

        -- Reuse the existing ready/supplemental data, but pretend it belongs
        -- to a second Discord user that shares the same guild membership.
        secondReady : String
        secondReady =
            String.replace currentDiscordUserIdString secondDiscordUserIdString discordOp0Ready

        secondSupplemental : String
        secondSupplemental =
            String.replace currentDiscordUserIdString secondDiscordUserIdString discordOp0ReadySupplemental
    in
    T.connectFrontend
        100
        sessionId
        ("/link-discord/?data=" ++ Codec.encodeToString 0 User.linkDiscordDataCodec secondAuth)
        desktopWindow
        (\userB ->
            [ userB.portEvent 10 "user_agent_from_js" (Json.Encode.string firefoxDesktop)
            , T.andThen
                120
                (\data ->
                    case findUntouchedBackendWebsocket data of
                        Just connection ->
                            [ T.websocketSendString 100 connection """{"t":null,"s":null,"op":10,"d":{"heartbeat_interval":41250,"_trace":["[\\"gateway-prd-arm-us-east1-d-swb5\\",{\\"micros\\":0.0}]"]}}""" ]

                        Nothing ->
                            [ T.checkState 0 (\_ -> Err "Couldn't find newly opened Discord websocket") ]
                )
            , T.andThen
                120
                (\data ->
                    case websocketByDiscordToken secondDiscordToken data of
                        Just ( connection, _ ) ->
                            [ T.websocketSendString 100 connection secondReady
                            , T.websocketSendString 100 connection secondSupplemental
                            ]

                        Nothing ->
                            [ T.checkState 0 (\_ -> Err "Second Discord websocket didn't send OP2 with the expected token") ]
                )
            ]
        )


findUntouchedBackendWebsocket : T.Data frontendModel backendModel -> Maybe Websocket.Connection
findUntouchedBackendWebsocket data =
    SeqDict.toList data.websockets
        |> List.filterMap
            (\( ( requestedBy, connection ), websocketState ) ->
                if requestedBy == RequestedByBackend && websocketState.closedAt == Nothing && Array.isEmpty websocketState.dataSent then
                    Just connection

                else
                    Nothing
            )
        |> List.head


infoEndpointResponse : String
infoEndpointResponse =
    """{"s":"unknown","v":136,"h":["ce04ec5a052111b470b778b6adec9470dd0ab1d2","881990760d6345c8ebcecb11eeb3d7c3caa48d52","5bf58bad725a2b57b8b04c61329291b3ddc57f89","121b2b6733a1d45f0aa03a86227cb260fa0aca63","dc23f82c404f7f9881562c94f59dddf1f291d0b5","a7f4d07c436ed96853c669d38f8591f0d64d57cd"],"o":"a12","p":15}"""


handleCustomRequest : String -> CustomRequest -> HttpResponse
handleCustomRequest discordStickerPacks { method, url, headers, body } =
    if String.startsWith "https://" url then
        case ( method, String.dropLeft 8 url |> String.split "/" ) of
            ( "GET", [ "discord.com", "api", "v9", "users", "@me" ] ) ->
                if List.Extra.count (\a -> a == ( "Authorization", "legit-token" )) headers == 1 && body == Nothing then
                    StringHttpResponse
                        { url = url, statusCode = 200, statusText = "OK", headers = Dict.empty }
                        """{"id":"184437096813953035","username":"at28727","avatar":"7c40cb63ea11096169c5a4dcb5825a3d","discriminator":"0","public_flags":0,"flags":0,"banner":null,"accent_color":null,"global_name":"AT2","avatar_decoration_data":null,"collectibles":null,"display_name_styles":null,"banner_color":null,"clan":null,"primary_guild":null,"mfa_enabled":false,"locale":"en-US","premium_type":0,"email":"a@a.se","verified":true,"phone":null,"nsfw_allowed":null,"linked_users":[],"bio":"","authenticator_types":[],"age_verification_status":1}"""

                else if List.Extra.count (\a -> a == ( "Authorization", secondDiscordToken )) headers == 1 && body == Nothing then
                    StringHttpResponse
                        { url = url, statusCode = 200, statusText = "OK", headers = Dict.empty }
                        ("""{"id":\"""" ++ secondDiscordUserIdString ++ """","username":"at-second","avatar":null,"discriminator":"0","public_flags":0,"flags":0,"banner":null,"accent_color":null,"global_name":"AT Second","avatar_decoration_data":null,"collectibles":null,"display_name_styles":null,"banner_color":null,"clan":null,"primary_guild":null,"mfa_enabled":false,"locale":"en-US","premium_type":0,"email":"second@a.se","verified":true,"phone":null,"nsfw_allowed":null,"linked_users":[],"bio":"","authenticator_types":[],"age_verification_status":1}""")

                else
                    StringHttpResponse
                        { url = url, statusCode = 403, statusText = "OK", headers = Dict.empty }
                        ""

            ( "GET", [ "discord.com", "api", "v9", "sticker-packs" ] ) ->
                StringHttpResponse
                    { url = url, statusCode = 200, statusText = "OK", headers = Dict.empty }
                    discordStickerPacks

            ( "POST", [ "discord.com", "api", "v9", "channels", _, "typing" ] ) ->
                StringHttpResponse
                    { url = url, statusCode = 200, statusText = "OK", headers = Dict.empty }
                    ""

            ( "POST", [ "discord.com", "api", "v9", "channels", channelId, "messages" ] ) ->
                StringHttpResponse
                    { url = url, statusCode = 200, statusText = "OK", headers = Dict.empty }
                    ("""{
    "id": "123456789012345678",
    "channel_id": \""""
                        ++ channelId
                        ++ """",
    "author": {
        "id": "111222333444555666",
        "username": "testuser",
        "discriminator": "0001",
        "avatar": null,
        "bot": false
    },
    "content": "Hello, world!",
    "timestamp": "2025-03-21T12:00:00.000Z",
    "edited_timestamp": null,
    "tts": false,
    "mention_everyone": false,
    "mention_roles": [],
    "attachments": [],
    "pinned": false,
    "type": 0
}"""
                    )

            ( "PUT", [ "discord.com", "api", "v9", "channels", _, "thread-members", "@me" ] ) ->
                StringHttpResponse { url = url, statusCode = 204, statusText = "OK", headers = Dict.empty } ""

            _ ->
                let
                    _ =
                        Debug.log "UnhandledHttpRequest" ( method, url )
                in
                UnhandledHttpRequest

    else
        let
            _ =
                Debug.log "UnhandledHttpRequest" url
        in
        UnhandledHttpRequest


type alias CustomRequest =
    { method : String
    , url : String
    , headers : List ( String, String )
    , body : Maybe Json.Decode.Value
    }


decodeCustomRequest : HttpRequest -> Maybe CustomRequest
decodeCustomRequest request =
    case request.body of
        T.JsonBody json ->
            Json.Decode.decodeValue
                (Json.Decode.map4
                    CustomRequest
                    (Json.Decode.field "method" Json.Decode.string)
                    (Json.Decode.field "url" Json.Decode.string)
                    (Json.Decode.field
                        "headers"
                        (Json.Decode.list
                            (Json.Decode.map2
                                Tuple.pair
                                (Json.Decode.field "key" Json.Decode.string)
                                (Json.Decode.field "value" Json.Decode.string)
                            )
                        )
                    )
                    (Json.Decode.field "body" (Json.Decode.nullable Json.Decode.value))
                )
                json
                |> Result.toMaybe

        _ ->
            Nothing


handleInternalRequests : String -> HttpRequest -> List String -> HttpResponse
handleInternalRequests discordStickerPacks currentRequest rest =
    if List.member ( "x-secret-key", Env.secretKey ) currentRequest.headers then
        case rest of
            [ "upload-backup", filename ] ->
                if String.startsWith "backend-export-" filename then
                    StringHttpResponse
                        { url = currentRequest.url
                        , statusCode = 200
                        , statusText = "OK"
                        , headers = Dict.empty
                        }
                        ""

                else
                    UnhandledHttpRequest

            [ "custom-request" ] ->
                case decodeCustomRequest currentRequest of
                    Just customRequest2 ->
                        handleCustomRequest discordStickerPacks customRequest2

                    Nothing ->
                        let
                            _ =
                                Debug.log "Failed to decode custom request" ()
                        in
                        UnhandledHttpRequest

            [ "vapid" ] ->
                StringHttpResponse
                    { url = currentRequest.url
                    , statusCode = 200
                    , statusText = "OK"
                    , headers = Dict.empty
                    }
                    "BIMi0iQoEXBXE3DyvGBToZfTfC8OyTn5lr_8eMvGBzJbxdEzv4wXFwIOEna_X3NJnCqIMbZX81VgSOFCjYda0bo,Ik2bRdqy_1dPMyiHxJX3_mV_t5R0GpQjsIu71E4MkCU"

            [ "push-notification" ] ->
                StringHttpResponse
                    { url = currentRequest.url
                    , statusCode = 200
                    , statusText = "OK"
                    , headers = Dict.empty
                    }
                    ""

            [ "regenerate-server-secret" ] ->
                StringHttpResponse
                    { url = currentRequest.url
                    , statusCode = 200
                    , statusText = "OK"
                    , headers = Dict.empty
                    }
                    regeneratedServerSecretValue

            [ "embed" ] ->
                case currentRequest.body of
                    T.JsonBody json ->
                        case Json.Decode.decodeValue (Json.Decode.field "url" Json.Decode.string) json of
                            Ok embedUrl ->
                                StringHttpResponse
                                    { url = currentRequest.url
                                    , statusCode = 200
                                    , statusText = "OK"
                                    , headers = Dict.empty
                                    }
                                    (Json.Encode.object
                                        [ ( "title", Json.Encode.string ("Title for " ++ embedUrl) )
                                        , if String.startsWith "https://elm.camp" embedUrl then
                                            ( "image"
                                            , Json.Encode.object
                                                [ ( "url", Json.Encode.string "https://elm.camp/logo-26.png" )
                                                , ( "width", Json.Encode.int 1080 )
                                                , ( "height", Json.Encode.int 1080 )
                                                , ( "format", Json.Encode.string "Png" )
                                                ]
                                            )

                                          else
                                            ( "image", Json.Encode.null )
                                        , ( "description", Json.Encode.string ("Description for " ++ embedUrl) )
                                        , ( "created_at", Json.Encode.null )
                                        ]
                                        |> Json.Encode.encode 0
                                    )

                            Err _ ->
                                StringHttpResponse
                                    { url = currentRequest.url
                                    , statusCode = 500
                                    , statusText = "Bad request"
                                    , headers = Dict.empty
                                    }
                                    ""

                    _ ->
                        StringHttpResponse
                            { url = currentRequest.url
                            , statusCode = 500
                            , statusText = "Bad request"
                            , headers = Dict.empty
                            }
                            ""

            _ ->
                UnhandledHttpRequest

    else
        StringHttpResponse
            { url = currentRequest.url
            , statusCode = 403
            , statusText = "Forbidden"
            , headers = Dict.empty
            }
            ""


startTest :
    String
    -> Time.Posix
    -> T.Config toBackend FrontendMsg FrontendModel toFrontend backendMsg backendModel
    -> List (T.Action toBackend FrontendMsg FrontendModel toFrontend backendMsg backendModel)
    -> T.EndToEndTest toBackend FrontendMsg FrontendModel toFrontend backendMsg backendModel
startTest name startTime2 config actions =
    T.start
        name
        startTime2
        config
        [ T.connectFrontend
            100
            sessionIdAttacker
            "/"
            desktopWindow
            (\attacker ->
                [ T.collapsableGroup
                    "Attacker setup"
                    [ handleLogin firefoxDesktop attackerEmail attacker
                    , attacker.update 100 Types.EnableToFrontendLogging
                    ]
                , T.group actions
                , attacker.checkModel
                    100
                    (\model ->
                        case model of
                            Types.Loaded loaded ->
                                case loaded.toFrontendLogs of
                                    Just toFrontendLogs ->
                                        if Array.isEmpty toFrontendLogs then
                                            Ok ()

                                        else
                                            Err "Attacker got ToFrontend when it shouldn't have"

                                    Nothing ->
                                        Err "Should have been logging toFrontend"

                            Types.Loading _ ->
                                Err "Attacker didn't load for some reason"
                    )
                ]
            )
        ]


attackerShouldNotGetThisToFrontend : ToFrontend -> Bool
attackerShouldNotGetThisToFrontend toFrontend =
    case toFrontend of
        CheckLoginResponse _ ->
            False

        LoginWithTokenResponse _ ->
            False

        GetLoginTokenRateLimited ->
            False

        SignupsDisabledResponse ->
            False

        LoggedOutSession ->
            False

        AdminToFrontend _ ->
            True

        LocalChangeResponse _ localChange ->
            case localChange of
                Local_Invalid ->
                    False

                Local_Admin _ ->
                    True

                Local_SendMessage _ _ _ _ _ ->
                    True

                Local_Discord_SendMessage _ _ _ _ _ ->
                    True

                Local_NewChannel _ _ _ _ ->
                    True

                Local_EditChannel _ _ _ _ ->
                    True

                Local_DeleteChannel _ _ ->
                    True

                Local_DeleteGuild _ ->
                    True

                Local_NewInviteLink _ _ _ ->
                    True

                Local_DeleteInviteLink _ _ ->
                    True

                Local_NewGuild _ _ _ ->
                    False

                Local_MemberTyping _ _ ->
                    True

                Local_AddReactionEmoji _ _ _ ->
                    True

                Local_RemoveReactionEmoji _ _ _ ->
                    True

                Local_SendEditMessage _ _ _ _ _ ->
                    True

                Local_Discord_SendEditGuildMessage _ _ _ _ _ _ ->
                    True

                Local_Discord_SendEditDmMessage _ _ _ _ ->
                    True

                Local_MemberEditTyping _ _ _ ->
                    True

                Local_SetLastViewed _ _ ->
                    True

                Local_DeleteMessage _ _ ->
                    True

                Local_CurrentlyViewing setViewing ->
                    case setViewing of
                        ViewDm _ _ ->
                            False

                        ViewDmThread _ _ _ ->
                            False

                        ViewDiscordDm _ _ _ ->
                            True

                        ViewChannel guildId _ _ ->
                            guildId == legitGuildId

                        ViewChannelThread _ _ _ _ ->
                            True

                        ViewDiscordChannel _ _ _ _ ->
                            True

                        ViewDiscordChannelThread _ _ _ _ _ ->
                            True

                        StopViewingChannel ->
                            False

                Local_SetName _ ->
                    False

                Local_LoadChannelMessages _ _ _ ->
                    True

                Local_LoadThreadMessages _ _ _ _ ->
                    True

                Local_Discord_LoadChannelMessages _ _ _ ->
                    True

                Local_Discord_LoadThreadMessages _ _ _ _ ->
                    True

                Local_SetGuildNotificationLevel _ _ ->
                    True

                Local_SetDiscordGuildNotificationLevel _ _ _ ->
                    True

                Local_SetNotificationMode _ ->
                    False

                Local_RegisterPushSubscription _ _ ->
                    False

                Local_TextEditor _ ->
                    False

                Local_UnlinkDiscordUser _ ->
                    True

                Local_StartReloadingDiscordUser _ _ ->
                    True

                Local_LinkDiscordAcknowledgementIsChecked _ ->
                    False

                Local_SetDomainWhitelist _ _ ->
                    False

                Local_SetEmojiCategory _ ->
                    False

                Local_SetEmojiSkinTone _ ->
                    False

                Local_VoiceChatChange _ ->
                    True

                Local_AddCustomEmojisToUser _ ->
                    False

                Local_Go _ _ ->
                    True

        ChangeBroadcast localMsg ->
            case localMsg of
                Types.LocalChange _ _ ->
                    True

                Types.ServerChange serverChange ->
                    case serverChange of
                        Types.Server_SendMessage _ _ _ _ _ _ _ ->
                            True

                        --RichText.toString SeqDict.empty message |> String.contains "sensitive"
                        Types.Server_Discord_SendMessage _ _ _ _ _ _ ->
                            True

                        Types.Server_NewChannel _ _ _ _ ->
                            True

                        Types.Server_EditChannel _ _ _ _ ->
                            True

                        Types.Server_DeleteChannel _ _ ->
                            True

                        Types.Server_DeleteGuild _ ->
                            True

                        Types.Server_NewInviteLink _ _ _ _ ->
                            True

                        Types.Server_DeleteInviteLink _ _ ->
                            True

                        Types.Server_MemberJoined _ _ _ _ ->
                            True

                        Types.Server_YouJoinedGuildByInvite result ->
                            case result of
                                Ok _ ->
                                    True

                                Err _ ->
                                    False

                        Types.Server_MemberTyping _ _ _ _ ->
                            True

                        Types.Server_DiscordGuildMemberTyping _ _ _ _ _ ->
                            True

                        Types.Server_DiscordDmMemberTyping _ _ _ ->
                            True

                        Types.Server_AddReactionEmoji _ _ _ _ ->
                            False

                        Types.Server_RemoveReactionEmoji _ _ _ _ ->
                            False

                        Types.Server_DiscordAddReactionGuildEmoji _ _ _ _ _ ->
                            True

                        Types.Server_DiscordAddReactionDmEmoji _ _ _ _ ->
                            True

                        Types.Server_DiscordRemoveReactionGuildEmoji _ _ _ _ _ ->
                            True

                        Types.Server_DiscordRemoveReactionDmEmoji _ _ _ _ ->
                            True

                        Types.Server_SendEditMessage _ _ _ _ _ _ ->
                            True

                        Types.Server_DiscordSendEditGuildMessage _ _ _ _ _ _ ->
                            True

                        Types.Server_DiscordSendEditDmMessage _ _ _ _ ->
                            True

                        Types.Server_MemberEditTyping _ _ _ _ ->
                            False

                        Types.Server_DeleteMessage _ _ ->
                            False

                        Types.Server_DiscordDeleteGuildMessage _ _ _ ->
                            True

                        Types.Server_DiscordDeleteDmMessage _ _ ->
                            True

                        Types.Server_SetName _ _ ->
                            True

                        Types.Server_SetUserIcon _ _ ->
                            False

                        Types.Server_PushNotificationsReset _ ->
                            True

                        Types.Server_SetGuildNotificationLevel _ _ ->
                            True

                        Types.Server_SetDiscordGuildNotificationLevel _ _ ->
                            True

                        Types.Server_PushNotificationFailed _ _ ->
                            True

                        Types.Server_NewSession _ _ ->
                            True

                        Types.Server_LoggedOut _ ->
                            True

                        Types.Server_CurrentlyViewing _ _ ->
                            True

                        Types.Server_TextEditor _ ->
                            True

                        Types.Server_LinkDiscordUser _ _ ->
                            False

                        Types.Server_UnlinkDiscordUser _ ->
                            True

                        Types.Server_DiscordChannelCreated _ _ _ _ ->
                            True

                        Types.Server_DiscordDmChannelCreated _ _ ->
                            True

                        Types.Server_DiscordNeedsAuthAgain _ ->
                            True

                        Types.Server_DiscordUserLoadingDataIsDone _ _ ->
                            True

                        Types.Server_StartReloadingDiscordUser _ _ ->
                            True

                        Types.Server_LoadingDiscordChannelChanged _ _ ->
                            True

                        Types.Server_LoadAdminData _ ->
                            True

                        Types.Server_NewLog _ _ ->
                            True

                        Types.Server_GotGuildMessageEmbed _ _ _ _ ->
                            True

                        Types.Server_GotDmMessageEmbed _ _ _ ->
                            True

                        Types.Server_GotDiscordGuildMessageEmbed _ _ _ _ ->
                            True

                        Types.Server_GotDiscordDmMessageEmbed _ _ _ ->
                            True

                        Types.Server_DiscordGuildJoinedOrCreated _ _ ->
                            True

                        Types.Server_DiscordUpdateChannel _ _ _ _ ->
                            True

                        Types.Server_UpdateDiscordMembers _ _ ->
                            True

                        Types.Server_DiscordGuildMemberJoined _ _ _ _ _ ->
                            True

                        Types.Server_LinkedDiscordUserStickersLoaded _ ->
                            True

                        Types.Server_VoiceChatChange _ ->
                            True

                        Types.Server_LinkedDiscordUserCustomEmojisLoaded _ ->
                            True

                        Types.Server_Go _ _ _ ->
                            True

                        Types.Server_SetGuildIcon _ _ ->
                            True

        TwoFactorAuthenticationToFrontend _ ->
            False

        AiChatToFrontend _ ->
            False

        YouConnected _ ->
            True

        ReloadDataResponse _ ->
            False

        LinkDiscordResponse _ ->
            False

        ProfilePictureEditorToFrontend _ ->
            False

        GetPublicGoMatchResponse _ ->
            False


allAttackerToBackendChanges : List ToBackend
allAttackerToBackendChanges =
    [ CheckLoginRequest InitialLoadRequested_None
    , LoginWithTokenRequest InitialLoadRequested_None 0 UserAgent.init
    , LoginWithTwoFactorRequest InitialLoadRequested_None 0 UserAgent.init
    , GetLoginTokenRequest (Unsafe.emailAddress "attacker@example.com" |> Untrusted.untrust)
    , AdminToBackend (Pages.Admin.ExportBackendRequest Pages.Admin.ExportAll)
    , LocalModelChangeRequest (ChangeId 0) Local_Invalid
    , TwoFactorToBackend TwoFactorAuthentication.EnableTwoFactorAuthenticationRequest
    , TwoFactorToBackend (TwoFactorAuthentication.DisableTwoFactorAuthenticationRequest 123456)
    , JoinGuildByInviteRequest (Id.fromInt 0) (SecretId "fake-invite-link")
    , FinishUserCreationRequest InitialLoadRequested_None (Unsafe.personName "hacked") UserAgent.init
    , AiChatToBackend (AiChat.AiMessageRequestSimple (AiModelName "model") (AiChat.RespondId 0) "hacked")
    , ReloadDataRequest InitialLoadRequested_None
    , LinkSlackOAuthCode (Slack.OAuthCode "fake-code") (SessionIdHash "fake-hash")
    , LinkDiscordRequest { discordUserAuth | token = "attacker-token" }
    , ProfilePictureEditorToBackend (ImageEditor.ChangeUserAvatarRequest (FileStatus.FileHash "fake-hash"))
    , ProfilePictureEditorToBackend (ImageEditor.ChangeGuildIconRequest (Id.fromInt 0) (FileStatus.FileHash "fake-hash"))
    , AdminDataRequest Nothing
    , GetPublicGoMatchRequest (SecretId.fromString "attacker-public-id")
    , -- Make sure this one is last
      LogOutRequest
    ]


legitGuildId : Id GuildId
legitGuildId =
    Id.fromInt 0


allAttackerLocalChanges : List LocalChange
allAttackerLocalChanges =
    let
        normalUserId : Id UserId
        normalUserId =
            Id.fromInt 1

        channelId : Id ChannelId
        channelId =
            Id.fromInt 0

        messageTime =
            Time.millisToPosix 99999

        normalText =
            NonemptyString 'h' "acked"

        discordUserId =
            Discord.idFromUInt64 (Unsafe.uint64 "184437096813953035")

        discordGuildId =
            Discord.idFromUInt64 (Unsafe.uint64 "705745250815311942")

        discordChannelId =
            Discord.idFromUInt64 (Unsafe.uint64 "1072828564317159465")

        discordPrivateChannelId =
            Discord.idFromUInt64 (Unsafe.uint64 "1215077285749858324")

        guildOrDmId_dm : AnyGuildOrDmId
        guildOrDmId_dm =
            GuildOrDmId_Dm normalUserId |> GuildOrDmId

        guildOrDmId_guild : AnyGuildOrDmId
        guildOrDmId_guild =
            GuildOrDmId_Guild legitGuildId channelId |> GuildOrDmId

        discordGuildOrDmId_guild : DiscordGuildOrDmId
        discordGuildOrDmId_guild =
            DiscordGuildOrDmId_Guild discordUserId discordGuildId discordChannelId

        discordGuildOrDmId_dm : DiscordGuildOrDmId
        discordGuildOrDmId_dm =
            DiscordGuildOrDmId_Dm { currentUserId = discordUserId, channelId = discordPrivateChannelId }

        threadRouteWithMessage =
            NoThreadWithMessage (Id.fromInt 0)

        threadRouteWithMaybeMessage =
            NoThreadWithMaybeMessage (Just (Id.fromInt 0))

        emoji =
            EmojiOrCustomEmoji_Emoji (Emoji.UnicodeEmoji "👍")

        discordDmData : DiscordGuildOrDmId_DmData
        discordDmData =
            { currentUserId = discordUserId
            , channelId = discordPrivateChannelId
            }

        brokenDomain : Domain
        brokenDomain =
            RichText.urlToDomain
                { protocol = Https
                , host = ""
                , port_ = Nothing
                , path = ""
                , query = Nothing
                , fragment = Nothing
                }
    in
    [ Local_AddReactionEmoji guildOrDmId_dm threadRouteWithMessage emoji
    , Local_AddReactionEmoji guildOrDmId_guild threadRouteWithMessage emoji
    , Local_Admin (Pages.Admin.SetSignupsEnabled True)
    , Local_CurrentlyViewing StopViewingChannel
    , Local_DeleteChannel legitGuildId channelId
    , Local_DeleteGuild legitGuildId
    , Local_DeleteMessage guildOrDmId_dm threadRouteWithMessage
    , Local_DeleteMessage guildOrDmId_guild threadRouteWithMessage
    , Local_Discord_LoadChannelMessages discordGuildOrDmId_guild (Id.fromInt 0) EmptyPlaceholder
    , Local_Discord_LoadThreadMessages discordGuildOrDmId_guild (Id.fromInt 0) (Id.fromInt 0) EmptyPlaceholder
    , Local_Discord_LoadChannelMessages discordGuildOrDmId_dm (Id.fromInt 0) EmptyPlaceholder
    , Local_Discord_LoadThreadMessages discordGuildOrDmId_dm (Id.fromInt 0) (Id.fromInt 0) EmptyPlaceholder
    , Local_Discord_SendEditDmMessage messageTime discordDmData (Id.fromInt 0) normalText
    , Local_Discord_SendEditGuildMessage messageTime discordUserId discordGuildId discordChannelId threadRouteWithMessage normalText
    , Local_Discord_SendMessage messageTime discordGuildOrDmId_guild normalText threadRouteWithMaybeMessage SeqDict.empty
    , Local_Discord_SendMessage messageTime discordGuildOrDmId_dm normalText threadRouteWithMaybeMessage SeqDict.empty
    , Local_EditChannel legitGuildId channelId (Unsafe.channelName "hacked") ChannelDescription.empty
    , Local_Invalid
    , Local_LinkDiscordAcknowledgementIsChecked True
    , Local_LoadChannelMessages (GuildOrDmId_Dm normalUserId) (Id.fromInt 0) EmptyPlaceholder
    , Local_LoadThreadMessages (GuildOrDmId_Dm normalUserId) (Id.fromInt 0) (Id.fromInt 0) EmptyPlaceholder
    , Local_MemberEditTyping messageTime guildOrDmId_dm threadRouteWithMessage
    , Local_MemberTyping messageTime ( guildOrDmId_dm, NoThread )
    , Local_LoadChannelMessages (GuildOrDmId_Guild legitGuildId channelId) (Id.fromInt 0) EmptyPlaceholder
    , Local_LoadThreadMessages (GuildOrDmId_Guild legitGuildId channelId) (Id.fromInt 0) (Id.fromInt 0) EmptyPlaceholder
    , Local_MemberEditTyping messageTime guildOrDmId_guild threadRouteWithMessage
    , Local_MemberTyping messageTime ( guildOrDmId_guild, NoThread )
    , Local_NewChannel messageTime legitGuildId (Unsafe.channelName "hacked") ChannelDescription.empty
    , Local_NewGuild messageTime (Unsafe.guildName "hacked") EmptyPlaceholder
    , Local_NewInviteLink messageTime legitGuildId EmptyPlaceholder
    , Local_RegisterPushSubscription (Time.millisToPosix 9) (GotSubscribeData UserEnabledNotifications { endpoint = domain, expirationTime = Nothing, keys = { auth = "auth", p256dh = "p256dh" } })
    , Local_RegisterPushSubscription (Time.millisToPosix 9) (SubscribeJsException "")
    , Local_RemoveReactionEmoji guildOrDmId_guild threadRouteWithMessage emoji
    , Local_SendEditMessage messageTime (GuildOrDmId_Dm normalUserId) threadRouteWithMessage normalText SeqDict.empty
    , Local_SendMessage messageTime (GuildOrDmId_Guild legitGuildId channelId) normalText threadRouteWithMaybeMessage SeqDict.empty
    , Local_RemoveReactionEmoji guildOrDmId_dm threadRouteWithMessage emoji
    , Local_SendEditMessage messageTime (GuildOrDmId_Dm normalUserId) threadRouteWithMessage normalText SeqDict.empty
    , Local_SendMessage messageTime (GuildOrDmId_Dm normalUserId) normalText threadRouteWithMaybeMessage SeqDict.empty
    , Local_SetDiscordGuildNotificationLevel discordUserId discordGuildId User.NotifyOnEveryMessage
    , Local_SetDomainWhitelist True (Domain "example.com")
    , Local_SetEmojiCategory (Emoji.EmojiCategory Emoji.Activities)
    , Local_SetEmojiSkinTone (Just Emoji.SkinTone1)
    , Local_SetGuildNotificationLevel legitGuildId User.NotifyOnEveryMessage
    , Local_SetLastViewed guildOrDmId_guild threadRouteWithMessage
    , Local_SetLastViewed guildOrDmId_dm threadRouteWithMessage
    , Local_SetName (Unsafe.personName "hacked")
    , Local_SetNotificationMode NoNotifications
    , Local_StartReloadingDiscordUser messageTime discordUserId
    , Local_TextEditor TextEditor.Local_Reset
    , Local_UnlinkDiscordUser discordUserId
    , Local_StartReloadingDiscordUser messageTime discordUserId
    , Local_LinkDiscordAcknowledgementIsChecked True
    , Local_SetDomainWhitelist False brokenDomain
    , Local_SetDomainWhitelist True brokenDomain
    , Local_SetEmojiCategory (EmojiCategory Emoji.Components)
    , Local_SetEmojiSkinTone Nothing
    , Local_SetEmojiSkinTone (Just SkinTone5)
    , Local_AddCustomEmojisToUser (NonemptySet.fromNonemptyList (Nonempty (Id.fromInt 0) []))
    , Local_VoiceChatChange (Call.Local_Join startTime (Call.DmRoomId normalUserId) EmptyPlaceholder)
    , Local_VoiceChatChange (Call.Local_Leave startTime)
    , Local_VoiceChatChange (Call.Local_RenegotiateAnswer (Cloudflare.sdpFromString "") EmptyPlaceholder)
    , Local_VoiceChatChange Call.Local_PublishConnected
    , Local_Go
        { otherUserId = Broadcast.adminUserId }
        (Go.StartMatch
            (Time.millisToPosix 0)
            { width = Go.boardSize9
            , height = Go.boardSize9
            , handicap = 0
            , komiHalfPoints = Go.KomiHalfPoints 2
            , timeControl = Nothing
            , blackPlayer = normalUserId
            , whitePlayer = Broadcast.adminUserId
            }
        )
    , Local_Go
        { otherUserId = Broadcast.adminUserId }
        (Go.CreatePublicLink (Id.fromInt 0) EmptyPlaceholder)
    , Local_DeleteInviteLink legitGuildId (SecretId.fromString "123")
    ]


currentDiscordUserId : Discord.Id Discord.UserId
currentDiscordUserId =
    Unsafe.uint64 currentDiscordUserIdString |> Discord.idFromUInt64


currentDiscordUserIdString : String
currentDiscordUserIdString =
    "184437096813953035"


secondDiscordUserId : Discord.Id Discord.UserId
secondDiscordUserId =
    Unsafe.uint64 secondDiscordUserIdString |> Discord.idFromUInt64


secondDiscordUserIdString : String
secondDiscordUserIdString =
    "555555555555555555"


secondDiscordToken : String
secondDiscordToken =
    "legit-token-2"


botTestGuild : Discord.Id Discord.GuildId
botTestGuild =
    Unsafe.uint64 "705745250815311942" |> Discord.idFromUInt64


botTestGuild_ChannelA : Discord.Id Discord.ChannelId
botTestGuild_ChannelA =
    Unsafe.uint64 "1072828564317159465" |> Discord.idFromUInt64


checkNoErrorLogs : T.Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
checkNoErrorLogs =
    T.checkState
        100
        (\data ->
            case List.filterMap (isLogErrorEmail adminEmail) data.httpRequests of
                [] ->
                    Ok ()

                errors ->
                    "Error logs detected: " ++ String.join ", " errors |> Err
        )


inviteUser :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> (T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel -> List (T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel))
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
inviteUser admin continueWith =
    [ admin.click 100 (Dom.id "guild_openGuild_0")
    , admin.click 100 (Dom.id "guild_inviteLinkCreatorRoute")
    , admin.click 100 (Dom.id "guild_createInviteLink")
    , admin.click 100 (Dom.id "guild_copyText")
    , T.andThen
        100
        (\data ->
            case
                List.filter
                    (\portRequest -> portRequest.clientId == admin.clientId && portRequest.portName == "copy_to_clipboard_to_js")
                    data.portRequests
            of
                [ portRequest ] ->
                    case Json.Decode.decodeValue Json.Decode.string portRequest.value of
                        Ok copyText ->
                            [ if String.startsWith Env.domain copyText then
                                T.connectFrontend
                                    100
                                    sessionId1
                                    (String.dropLeft (String.length Env.domain) copyText)
                                    desktopWindow
                                    (\user ->
                                        [ user.portEvent 10 "user_agent_from_js" (Json.Encode.string firefoxDesktop)
                                        , handleLoginFromLoginPage userEmail user
                                        , user.input 100 (Dom.id "loginForm_name") "Sven"
                                        , user.click 100 (Dom.id "loginForm_submit")
                                        , T.group (continueWith user)
                                        ]
                                    )

                              else
                                admin.checkModel 100 (\_ -> Err "Copied invalid link")
                            ]

                        Err _ ->
                            [ admin.checkModel 100 (\_ -> Err "Didn't decode port") ]

                _ ->
                    [ admin.checkModel 100 (\_ -> Err "Didn't copy link") ]
        )
    ]
        |> T.collapsableGroup "Invite user"


inviteUserAndDmChat : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
inviteUserAndDmChat config =
    startTest
        "Invite user and then have DM chat"
        startTime
        config
        [ T.connectFrontend
            100
            sessionId0
            "/"
            desktopWindow
            (\admin ->
                [ handleLogin firefoxDesktop adminEmail admin
                , inviteUser
                    admin
                    (\user ->
                        [ user.click 1000 (Dom.id "guild_openDm_0")
                        , writeMessage user 100 "Hello"
                        , admin.click 100 (Dom.id "guildsColumn_openDm_1")
                        , writeMessage user 100 "Hello 2"
                        , writeMessage admin 100 "Hello from *admin*"
                        , user.checkView
                            100
                            (\html ->
                                Test.Html.Query.findAll [ Test.Html.Selector.exactText "Sven" ] html
                                    |> Test.Html.Query.count (Expect.equal 2)
                            )
                        , createThread user (Id.fromInt 1)
                        , writeMessage user 100 "Writing in thread"
                        , admin.checkView
                            100
                            (\html ->
                                Test.Html.Query.find [ Test.Html.Selector.id "guild_threadStarterIndicator_1" ] html
                                    |> Test.Html.Query.has
                                        [ Test.Html.Selector.containing [ Test.Html.Selector.exactText "Sven" ]
                                        ]
                            )
                        , admin.click 100 (Dom.id "guild_threadStarterIndicator_1")
                        ]
                    )
                ]
            )
        ]


inactiveThreadsAreHiddenTest : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
inactiveThreadsAreHiddenTest config =
    T.start
        "Inactive threads are hidden"
        startTime
        config
        [ T.connectFrontend
            100
            sessionId0
            "/"
            desktopWindow
            (\admin ->
                [ handleLogin firefoxDesktop adminEmail admin
                , inviteUser
                    admin
                    (\user ->
                        [ writeMessage user 100 "Hello!"
                        , admin.click 100 (Dom.id "guild_openChannel_0")
                        , writeMessage admin 100 "Hello from admin!"
                        , createThread admin (Id.fromInt 0)
                        , writeMessage admin 100 "Hello from admin in thread!"
                        , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewThread_0_0" ])
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewThread_0_0" ])
                        , admin.click 100 (Dom.id "guild_openChannel_0")
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewThread_0_0" ])
                        ]
                    )
                ]
            )
        , T.connectFrontend
            (Duration.days 7.1 |> Duration.inMilliseconds)
            sessionId0
            "/"
            desktopWindow
            (\admin ->
                [ admin.portEvent 10 "user_agent_from_js" (Json.Encode.string firefoxDesktop)
                , admin.click 100 (Dom.id "guild_openGuild_0")
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_viewThread_0_0" ])
                , admin.click 100 (Dom.id "guild_threadStarterIndicator_0")
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewThread_0_0" ])
                , admin.navigateBack 100
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_viewThread_0_0" ])
                , admin.click 100 (Dom.id "guild_threadStarterIndicator_0")
                , writeMessage admin 100 "Hello again from thread!"
                , admin.navigateBack 100
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewThread_0_0" ])
                ]
            )
        ]


goMatchTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
goMatchTest normalConfig =
    startTest
        "Two users play a Go match, one leaves and rejoins, then start a new match"
        startTime
        normalConfig
        [ T.connectFrontend
            100
            sessionId0
            "/"
            tallDesktopWindow
            (\admin ->
                [ handleLogin firefoxDesktop adminEmail admin
                , inviteUser
                    admin
                    (\user ->
                        [ user.click 1000 (Dom.id "guild_openDm_0")
                        , admin.click 100 (Dom.id "guild_openDm_1")
                        , admin.click 100 (Dom.id "guild_openGoMatch")
                        , admin.click 100 (Dom.id "go_start")
                        , user.click 100 (Dom.id "guild_goMatchStartedCard_0")
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "to move" ])
                        , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "to move" ])

                        -- A couple of opening moves: admin is Black (creator default), user is White
                        , admin.click 100 (Dom.id "go_cell_4_4")
                        , user.click 100 (Dom.id "go_cell_5_4")
                        , admin.click 100 (Dom.id "go_cell_4_5")
                        , user.click 100 (Dom.id "go_cell_5_5")

                        -- User leaves the game by navigating back out of the DM
                        , user.navigateBack 100

                        -- ... and then rejoins by clicking back into the DM and the Go tab
                        , T.connectFrontend
                            100
                            sessionId1
                            "/"
                            tallDesktopWindow
                            (\user2 ->
                                [ user2.portEvent 10 "user_agent_from_js" (Json.Encode.string firefoxDesktop)
                                , user2.click 100 (Dom.id "guild_friendLabel_0")
                                , user2.click 100 (Dom.id "guild_openGoMatch")
                                , user2.input 100 (Dom.id "go_matchSwitcher") "0"

                                -- A few more moves to confirm the state persisted
                                , admin.click 100 (Dom.id "go_cell_3_3")
                                , user2.click 100 (Dom.id "go_cell_3_4")

                                -- Wrap up the game: pass twice, finish marking, agree on scoring
                                , admin.click 100 (Dom.id "go_pass")
                                , user2.click 100 (Dom.id "go_pass")
                                , admin.click 100 (Dom.id "go_cell_3_6")
                                , admin.click 100 (Dom.id "go_doneMarking")
                                , user2.click 100 (Dom.id "go_agree")
                                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Final score" ])
                                , user2.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Final score" ])

                                -- Start a fresh match after the game has ended
                                , admin.click 100 (Dom.id "go_reset")
                                , admin.click 100 (Dom.id "go_start")
                                , user2.click 100 (Dom.id "guild_goMatchStartedCard_1")
                                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "to move" ])
                                , user2.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "to move" ])
                                , admin.click 100 (Dom.id "go_cell_3_3")
                                , user2.click 100 (Dom.id "go_cell_3_4")
                                , admin.click 100 (Dom.id "go_pass")
                                , user2.click 100 (Dom.id "go_pass")
                                , admin.click 100 (Dom.id "go_cell_3_6")
                                , admin.click 100 (Dom.id "go_doneMarking")
                                , user2.click 100 (Dom.id "go_disagree")
                                , admin.click 100 (Dom.id "go_cell_3_5")
                                ]
                            )
                        ]
                    )
                ]
            )
        ]


goTurnNotificationDotTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
goTurnNotificationDotTest normalConfig =
    startTest
        "Go channel header shows a red dot when it's the user's turn and they aren't viewing the match"
        startTime
        normalConfig
        [ T.connectFrontend
            100
            sessionId0
            "/"
            tallDesktopWindow
            (\admin ->
                [ handleLogin firefoxDesktop adminEmail admin
                , inviteUser
                    admin
                    (\user ->
                        [ user.click 1000 (Dom.id "guild_openDm_0")
                        , admin.click 100 (Dom.id "guild_openDm_1")
                        , admin.click 100 (Dom.id "guild_openGoMatch")
                        , admin.click 100 (Dom.id "go_start")
                        , user.click 100 (Dom.id "guild_goMatchStartedCard_0")

                        -- No dot for either user yet: admin is viewing the match,
                        -- and even though it's admin's turn, the user has no move pending
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_goMatchTurnDot" ])
                        , user.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_goMatchTurnDot" ])

                        -- Admin (Black) makes a move; now it's user's (White) turn
                        , admin.click 100 (Dom.id "go_cell_4_4")

                        -- User is still on the Go tab so no dot
                        , user.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_goMatchTurnDot" ])

                        -- User leaves the Go tab by switching to the chat description tab
                        , user.click 100 (Dom.id "guild_openDescription")

                        -- The dot should now appear since it's user's turn and they aren't viewing the match
                        , user.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.id "guild_goMatchTurnDot" ])

                        -- Admin still has no pending turn so no dot
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_goMatchTurnDot" ])

                        -- User clicks back to the Go tab; the dot disappears
                        , user.click 100 (Dom.id "guild_openGoMatch")
                        , user.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_goMatchTurnDot" ])

                        -- User makes their move; now it's admin's turn
                        , user.click 100 (Dom.id "go_cell_5_4")

                        -- Admin is viewing the match so no dot for them
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_goMatchTurnDot" ])

                        -- Admin switches away from the Go tab and should now see the dot
                        , admin.click 100 (Dom.id "guild_openDescription")
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.id "guild_goMatchTurnDot" ])
                        ]
                    )
                ]
            )
        ]


publicGoMatchViewTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
publicGoMatchViewTest normalConfig =
    startTest
        "A player shares a Go match link so a non-logged-in spectator can view it"
        startTime
        normalConfig
        [ T.connectFrontend
            100
            sessionId0
            "/"
            tallDesktopWindow
            (\admin ->
                [ handleLogin firefoxDesktop adminEmail admin
                , inviteUser
                    admin
                    (\user ->
                        [ T.connectFrontend
                            100
                            sessionIdAttacker
                            "/go-match/does-not-exist"
                            tallDesktopWindow
                            (\missingViewer ->
                                [ missingViewer.portEvent 10 "user_agent_from_js" (Json.Encode.string firefoxDesktop)
                                , missingViewer.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.text "Go match not found" ])
                                ]
                            )
                        , user.click 1000 (Dom.id "guild_openDm_0")
                        , admin.click 100 (Dom.id "guild_openDm_1")
                        , admin.click 100 (Dom.id "guild_openGoMatch")
                        , admin.click 100 (Dom.id "go_start")
                        , admin.click 100 (Dom.id "go_cell_4_4")
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "go_share" ])
                        , admin.click 100 (Dom.id "go_share")
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "go_share" ])
                        , admin.click 100 (Dom.id "go_shareLink_copy")
                        , T.andThen
                            100
                            (\data ->
                                let
                                    copyRequests =
                                        List.filter
                                            (\portRequest -> portRequest.portName == "copy_to_clipboard_to_js")
                                            data.portRequests
                                in
                                case copyRequests |> List.head of
                                    Just portRequest ->
                                        case Json.Decode.decodeValue Json.Decode.string portRequest.value of
                                            Ok shareUrl ->
                                                if String.startsWith Env.domain shareUrl then
                                                    [ T.connectFrontend
                                                        100
                                                        sessionId2
                                                        (String.dropLeft (String.length Env.domain) shareUrl)
                                                        tallDesktopWindow
                                                        (\viewer ->
                                                            [ viewer.portEvent 10 "user_agent_from_js" (Json.Encode.string firefoxDesktop)
                                                            , viewer.checkView
                                                                100
                                                                (Test.Html.Query.has [ Test.Html.Selector.id "public_go_container" ])
                                                            , viewer.checkView
                                                                100
                                                                (Test.Html.Query.has [ Test.Html.Selector.text "to move" ])
                                                            , viewer.checkView
                                                                100
                                                                (Test.Html.Query.hasNot [ Test.Html.Selector.id "go_pass" ])
                                                            , viewer.checkView
                                                                100
                                                                (Test.Html.Query.hasNot [ Test.Html.Selector.id "go_cell_5_5" ])
                                                            , tallSnapshot viewer 100 { name = "Spectating Go match" }
                                                            ]
                                                        )
                                                    ]

                                                else
                                                    [ admin.checkModel 100 (\_ -> Err ("Share URL didn't start with domain: " ++ shareUrl)) ]

                                            Err _ ->
                                                [ admin.checkModel 100 (\_ -> Err "Failed to decode share URL port value") ]

                                    Nothing ->
                                        [ admin.checkModel 100 (\_ -> Err "Expected a copy_to_clipboard_to_js port request after pressing share") ]
                            )
                        ]
                    )
                ]
            )
        ]


loginTests :
    Bool
    -> T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> List (T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
loginTests isMobile normalConfig =
    let
        windowSize : { width : number, height : number }
        windowSize =
            if isMobile then
                mobileWindow

            else
                desktopWindow

        userAgent =
            if isMobile then
                safariIphone

            else
                firefoxDesktop
    in
    [ startTest
        (if isMobile then
            "Test login mobile"

         else
            "Test login"
        )
        startTime
        normalConfig
        [ T.connectFrontend
            100
            sessionId0
            "/"
            windowSize
            (\client ->
                [ client.portEvent 10 "user_agent_from_js" (Json.Encode.string userAgent)
                , client.snapshotView 100 { name = "homepage" }
                , client.click 100 Pages.Home.loginButtonId
                , client.snapshotView 100 { name = "login" }
                , client.input 100 LoginForm.emailInputId "asdf123"
                , client.click 100 LoginForm.submitEmailButtonId
                , client.snapshotView 100 { name = "invalid email" }
                , client.input 100 LoginForm.emailInputId (EmailAddress.toString adminEmail)
                , client.snapshotView 100 { name = "valid email" }
                , client.click 100 LoginForm.submitEmailButtonId
                , T.andThen
                    100
                    (\data ->
                        case List.filterMap (isLoginEmail adminEmail) data.httpRequests of
                            loginCode :: _ ->
                                [ client.input 100 LoginForm.loginCodeInputId "12345678"
                                , client.snapshotView 100 { name = "invalid code" }
                                , client.input 100 LoginForm.loginCodeInputId (String.fromInt loginCode)
                                , client.snapshotView 100 { name = "logged in" }
                                ]

                            _ ->
                                [ T.checkState 100 (\_ -> Err "Didn't find login email") ]
                    )
                ]
            )
        , checkNoErrorLogs
        ]
    , startTest
        (if isMobile then
            "Enable 2FA mobile"

         else
            "Enable 2FA"
        )
        startTime
        normalConfig
        [ T.connectFrontend
            100
            sessionId0
            "/"
            windowSize
            (\user ->
                [ handleLogin userAgent adminEmail user
                , user.click 100 (Dom.id "guild_showUserOptions")
                , user.click 100 (Dom.id "userOverview_start2FaSetup")
                , tallSnapshot user 100 { name = "2FA setup" }
                , user.input 100 (Dom.id "userOverview_twoFactorCodeInput") "123123"
                , tallSnapshot user 100 { name = "2FA setup with wrong code" }
                , T.andThen
                    100
                    (\data ->
                        case SeqDict.get sessionId0 data.backend.sessions of
                            Just { userId } ->
                                case SeqDict.get userId data.backend.twoFactorAuthenticationSetup of
                                    Just { secret } ->
                                        case TwoFactorAuthentication.getConfig "" secret of
                                            Ok key ->
                                                [ user.input
                                                    100
                                                    (Dom.id "userOverview_twoFactorCodeInput")
                                                    (TwoFactorAuthentication.getCode startTime key
                                                        |> Maybe.withDefault 0
                                                        |> String.fromInt
                                                        |> String.padLeft LoginForm.twoFactorCodeLength '0'
                                                    )
                                                , user.checkView
                                                    100
                                                    (Test.Html.Query.has
                                                        [ Test.Html.Selector.exactText
                                                            "Two factor authentication enabled!"
                                                        ]
                                                    )
                                                , tallSnapshot user 100 { name = "2FA setup complete" }
                                                ]

                                            Err _ ->
                                                [ T.checkState 100 (\_ -> Err "Failed to get 2FA config") ]

                                    Nothing ->
                                        [ T.checkState 100 (\_ -> Err "Failed to get 2FA setup") ]

                            Nothing ->
                                [ T.checkState 100 (\_ -> Err "User not found") ]
                    )
                , user.click 100 (Dom.id "options_logout")
                ]
            )
        , T.connectFrontend
            100
            sessionId0
            "/"
            windowSize
            (\user ->
                [ handleLogin userAgent adminEmail user
                , tallSnapshot user 100 { name = "2FA login step" }
                , T.andThen
                    100
                    (\data ->
                        case SeqDict.get sessionId0 data.backend.pendingLogins of
                            Just (WaitingForTwoFactorToken { userId }) ->
                                case SeqDict.get userId data.backend.twoFactorAuthentication of
                                    Just { secret } ->
                                        case TwoFactorAuthentication.getConfig "" secret of
                                            Ok key ->
                                                [ user.input
                                                    100
                                                    (Dom.id "loginForm_twoFactorCodeInput")
                                                    (TwoFactorAuthentication.getCode startTime key
                                                        |> Maybe.withDefault 0
                                                        |> String.fromInt
                                                        |> String.padLeft LoginForm.twoFactorCodeLength '0'
                                                    )
                                                , user.click 100 (Dom.id "guild_showUserOptions")
                                                , user.checkView
                                                    100
                                                    (Test.Html.Query.has
                                                        [ Test.Html.Selector.exactText (PersonName.toString Backend.adminUser.name)
                                                        , Test.Html.Selector.exactText "Two factor authentication was enabled "
                                                        ]
                                                    )
                                                , tallSnapshot user 100 { name = "user overview with two factor already complete" }
                                                , user.click 100 (Dom.id "userOverview_startDisable2Fa")
                                                , tallSnapshot user 100 { name = "2FA disable prompt" }
                                                , user.input 100 (Dom.id "userOverview_disableTwoFactorCodeInput") "123123"
                                                , tallSnapshot user 100 { name = "2FA disable with wrong code" }
                                                , user.input
                                                    100
                                                    (Dom.id "userOverview_disableTwoFactorCodeInput")
                                                    (TwoFactorAuthentication.getCode startTime key
                                                        |> Maybe.withDefault 0
                                                        |> String.fromInt
                                                        |> String.padLeft LoginForm.twoFactorCodeLength '0'
                                                    )
                                                , user.checkView
                                                    100
                                                    (Test.Html.Query.has
                                                        [ Test.Html.Selector.exactText "Add two factor authentication" ]
                                                    )
                                                , T.checkState
                                                    100
                                                    (\data2 ->
                                                        if SeqDict.member userId data2.backend.twoFactorAuthentication then
                                                            Err "2FA should have been disabled for the user"

                                                        else
                                                            Ok ()
                                                    )
                                                , tallSnapshot user 100 { name = "2FA disabled" }
                                                ]

                                            Err _ ->
                                                [ T.checkState 100 (\_ -> Err "Failed to get 2FA config") ]

                                    Nothing ->
                                        [ T.checkState 100 (\_ -> Err "Failed to get 2FA setup") ]

                            _ ->
                                [ T.checkState 100 (\_ -> Err "Pending login not found") ]
                    )
                ]
            )
        ]
    ]
