module E2EHelper exposing
    ( BackendModel2(..)
    , CustomRequest
    , adminEmail
    , allAttackerLocalChanges
    , allAttackerToBackendChanges
    , andThenWebsocket
    , attachmentTestActions
    , attackerEmail
    , attackerPrivateDiscordChannelChanges
    , attackerShouldNotGetThisToFrontend
    , backendApp
    , botTestGuild
    , botTestGuild_ChannelA
    , botTestGuild_ForumA
    , checkNoErrorLogs
    , checkNoNotification
    , checkNotification
    , checkVoiceChatFromJsEvents
    , chromeDesktop
    , clickSpoiler
    , connectFourUsersAndJoinNewGuild
    , connectTwoUsersAndJoinNewGuild
    , createThread
    , currentDiscordUserId
    , decodeCustomRequest
    , desktopWindow
    , discordUserAuth
    , domain
    , drawWideZigzagStroke
    , drawZigzagStroke
    , drawingAnchorClick
    , editMostRecentMessageViaArrowUp
    , enableNotifications
    , expectPointsCloseTo
    , expectPolylineCount
    , expectPolylineScale
    , findEmbedImageMessage
    , findImageMessage
    , firefoxDesktop
    , focusEvent
    , fromJsAfterAdminOpensVoiceChat
    , fromJsAfterUserOpensVoiceChat
    , handleInternalRequests
    , handleLogin
    , handleLoginFromLoginPage
    , handlePortToJs
    , hasExactText
    , hasNotExactText
    , hasNotText
    , hasText
    , httpBasic
    , infoEndpointResponse
    , inviteUser
    , iphone14Window
    , isLogErrorEmail
    , isLoginEmail
    , isNotificationEmail
    , isOp2
    , joeEmail
    , lastGuildChannel
    , lastGuildChannelMessage
    , lastGuildChannelMessageAt
    , linkDiscordAndLogin
    , linkDiscordAndLoginSecondUser
    , linkDiscordUrl
    , linkSecondDiscordAccount
    , logoutOtherSessionButtonId
    , mockCloudflareSfu
    , noMissingMessages
    , openDm
    , privateDiscordChannelCreateEvent
    , privateDiscordChannelId
    , privateDiscordChannelMessageEvent
    , regeneratedServerSecretValue
    , regularDiscordChannelBecomesPrivateEvent
    , regularDiscordChannelCreateEvent
    , regularDiscordChannelId
    , safariIphone
    , scrollToBottom
    , scrollToMiddle
    , scrollToTop
    , secondDiscordToken
    , secondDiscordUserId
    , selectionEvent
    , sessionId0
    , sessionId1
    , sessionId2
    , sessionId4
    , sessionIdAttacker
    , startTest
    , startTime
    , startupDataJson
    , startupDataJsonWithInset
    , tallDesktopWindow
    , tallSnapshot
    , unwrapBackend
    , uploadImageAttachment
    , userEmail
    , websocketByDiscordToken
    , writeMessage
    , writeMessageMobile
    )

import AiChat exposing (AiModelName(..))
import Array
import Audio
import Backend
import Broadcast
import Call
import ChannelDescription
import Codec
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Dict
import Discord
import Drawing
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Lamdera as Lamdera exposing (SessionId)
import Effect.Test as T exposing (DelayInMs, HttpRequest, HttpResponse(..), RequestedBy(..))
import Effect.Websocket as Websocket
import EmailAddress exposing (EmailAddress)
import Embed
import Emoji exposing (EmojiOrCustomEmoji(..), SkinTone(..))
import Env
import Expect
import FileStatus
import Game
import Go
import Html.Attributes
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), DiscordGuildOrDmId_DmData, ExportChannelId(..), GuildId, GuildOrDmId(..), Id, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId)
import IdArray
import IdString
import ImageEditor
import Json.Decode
import Json.Encode
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import Local exposing (ChangeId(..))
import LocalState exposing (CallStatus(..))
import LoginForm
import Message
import MuteSettings
import NonemptyDict
import NonemptySet
import Pages.Admin
import Pages.Guild
import Pages.Home
import Parser exposing ((|.), (|=))
import Ports exposing (RegisterPushSubscription(..))
import Range exposing (Range)
import RichText exposing (Domain(..))
import SafeJson exposing (SafeJson(..))
import SecretId exposing (SecretId(..))
import SeqDict
import SessionIdHash exposing (SessionIdHash(..))
import Slack
import String.Nonempty exposing (NonemptyString(..))
import Svg.Attributes
import Test.Html.Query
import Test.Html.Selector
import TextEditor
import Time
import TwoFactorAuthentication
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, InitialLoadRequest(..), LocalChange(..), ToBackend(..), ToFrontend(..))
import Unsafe
import Untrusted
import Url exposing (Protocol(..), Url)
import User
import UserAgent
import UserSession exposing (NotificationMode(..), SetViewing(..), ToBeFilledInByBackend(..))
import WordSpellingGame


domain : Url
domain =
    { protocol = Url.Http, host = "localhost", port_ = Just 8000, path = "", query = Nothing, fragment = Nothing }


{-| The data the app loads through the load\_startup\_data ports at startup. timeOrigin is 0 so that event timeStamps in tests are used as-is.
-}
startupDataJson : Time.Posix -> String -> Json.Encode.Value
startupDataJson time userAgent =
    startupDataJsonWithInset time userAgent 0 False


{-| Like [`startupDataJson`](#startupDataJson) but with a nonzero safe-area top inset (e.g. a phone
notch), so a test can check that touch coordinates are adjusted for it.
-}
startupDataJsonWithInset : Time.Posix -> String -> Int -> Bool -> Json.Encode.Value
startupDataJsonWithInset time userAgent safeAreaInsetTop isPwa =
    Json.Encode.object
        [ ( "timeOrigin", Time.posixToMillis time |> toFloat |> Json.Encode.float )
        , ( "loadStartupDataTime", Time.posixToMillis time |> toFloat |> Json.Encode.float )
        , ( "userAgent", Json.Encode.string userAgent )
        , ( "scrollbarWidth", Json.Encode.int 20 )
        , ( "isPwa", Json.Encode.bool isPwa )
        , ( "notificationPermission", Json.Encode.string "denied" )
        , ( "safeAreaInsetTop", Json.Encode.int safeAreaInsetTop )
        , ( "devicePixelRatio", Json.Encode.float 2 )
        , ( "timezone", testTimezone )
        ]


{-| The timezone tests run in. It sits on UTC and puts its clocks forward an hour for the
summer of 2026, the way the UK does, so a timestamp either side of one of those changes lands
on a different moment even though a clock reads the same time on both.

Tests that don't care about any of this run at the start of 1970, which is before the first of
these changes, so what they see is plain UTC.

-}
testTimezone : Json.Encode.Value
testTimezone =
    Json.Encode.object
        [ ( "defaultOffset", Json.Encode.int 0 )
        , ( "eras"
          , Json.Encode.list
                (\( start, offset ) ->
                    Json.Encode.object
                        [ ( "start", Json.Encode.int start ), ( "offset", Json.Encode.int offset ) ]
                )
                -- Newest first, which is the order Time.customZone reads them in.
                [ ( 29881500, 0 ) -- 2026-10-25 01:00 UTC, clocks go back
                , ( 29579100, 60 ) -- 2026-03-29 01:00 UTC, clocks go forward
                ]
          )
        ]


handlePortToJs :
    { currentRequest : T.PortToJs, data : T.Data FrontendModel BackendModel2 }
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
                        [ Json.Encode.object
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

        "load_startup_data_to_js" ->
            -- Tests respond manually with startupDataJson so each test can control the user agent
            Nothing

        "audioPortToJs" ->
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


iphone14Window : { width : number, height : number }
iphone14Window =
    { width = 393, height = 852 }


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


{-| Detects an email-notification message sent to the given address and returns its text body.
-}
isNotificationEmail : EmailAddress -> HttpRequest -> Maybe String
isNotificationEmail emailAddress httpRequest =
    if httpRequest.url == "https://api.postmarkapp.com/email" then
        case httpRequest.body of
            T.JsonBody value ->
                case Json.Decode.decodeValue decodePostmark value of
                    Ok ( subject, to, body ) ->
                        if emailAddress == to && String.startsWith "New message from" subject then
                            Just body

                        else
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


sessionId4 : SessionId
sessionId4 =
    Lamdera.sessionIdFromString "sessionId4"


sessionId0Hash : SessionIdHash
sessionId0Hash =
    SessionIdHash.fromSessionId sessionId0


sessionId1Hash : SessionIdHash
sessionId1Hash =
    SessionIdHash.fromSessionId sessionId1


sessionId2Hash : SessionIdHash
sessionId2Hash =
    SessionIdHash.fromSessionId sessionId2


sessionIdAttackerHash : SessionIdHash
sessionIdAttackerHash =
    SessionIdHash.fromSessionId sessionIdAttacker


sessionId4Hash : SessionIdHash
sessionId4Hash =
    SessionIdHash.fromSessionId sessionId4


{-| The id of the "Logout other" button shown next to another session in the connected devices list.
Mirrors the id built in `UserOptions.viewConnectedDevice`.
-}
logoutOtherSessionButtonId : SessionId -> HtmlId
logoutOtherSessionButtonId sessionId =
    Dom.id ("options_logout_other_" ++ SessionIdHash.toString (SessionIdHash.fromSessionId sessionId))


handleLogin :
    String
    -> EmailAddress
    -> T.FrontendActions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> T.Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
handleLogin userAgent emailAddress client =
    [ T.andThen 10 (\data -> [ client.portEvent 0 "load_startup_data_from_js" (startupDataJson data.time userAgent) ])
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


wandaEmail : EmailAddress
wandaEmail =
    Unsafe.emailAddress "wanda@mail.com"


attackerEmail : EmailAddress
attackerEmail =
    Unsafe.emailAddress "hacker-joe@hotmail.com"


regeneratedServerSecretValue : String
regeneratedServerSecretValue =
    "regenerated-server-secret-from-rust-server"


enableNotifications : Bool -> T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2 -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
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


checkNotification : String -> String -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
checkNotification title body =
    T.checkState
        100
        (\data ->
            case
                List.filterMap
                    (\request ->
                        case request.body of
                            T.JsonBody json ->
                                case Codec.decodeValue Broadcast.pushNotificationCodec json of
                                    Ok pushNotification ->
                                        if
                                            (pushNotification.body == body)
                                                && (request.url == "http://localhost:3000/file/internal/push-notification")
                                        then
                                            Just pushNotification

                                        else
                                            Nothing

                                    Err _ ->
                                        Nothing

                            _ ->
                                Nothing
                    )
                    data.httpRequests
            of
                _ :: _ :: _ ->
                    Err ("Multiple notifications found for \"" ++ body ++ "\"")

                [ pushNotification ] ->
                    if pushNotification.title == title then
                        Ok ()

                    else
                        Err
                            ("Notification for \""
                                ++ body
                                ++ "\" has title \""
                                ++ pushNotification.title
                                ++ "\" but expected \""
                                ++ title
                                ++ "\""
                            )

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
    -> { currentRequest : HttpRequest, data : T.Data FrontendModel BackendModel2 }
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
                                    ConnectedToCall _ ->
                                        True

                                    NotInCall ->
                                        False
                            )
                        |> List.length
                        |> (+) acc
                )
                0
                (unwrapBackend data.backend).connections

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
                        ++ "\",\"type\":\"answer\"},\"tracks\":[{\"trackName\":\"0\"},{\"trackName\":\"2\"}]}"
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
    { data : T.Data FrontendModel BackendModel2, currentRequest : T.PortToJs }
    -> Maybe ( String, Json.Decode.Value )
mockVoiceChatPorts request =
    case Codec.decodeValue Call.voiceChatToJsCodec request.currentRequest.value of
        Ok ok ->
            case ok of
                Call.ToJs_StartCall _ ->
                    Nothing

                Call.ToJs_LeaveCall ->
                    Nothing

                Call.ToJs_PeerJoined _ ->
                    Nothing

                Call.ToJs_PeerLeft _ ->
                    -- JS removes the peer's video element and stops their tracks.
                    -- No response.
                    Nothing

                Call.ToJs_SetAudioInputEnabled _ ->
                    -- JS flips track.enabled in place. No response.
                    Nothing

                Call.ToJs_SetInput _ _ ->
                    -- JS replaces the track on the sender. No response.
                    Nothing

                Call.ToJs_SetVideoInputEnabled _ ->
                    -- Same as SetAudioInputEnabled. No response.
                    Nothing

                Call.ToJs_SetPeerVideoInputEnabled _ _ ->
                    -- JS clears that peer's canvas. No response.
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


{-| Cumulative `voice_chat_from_js` payloads expected once each person has the
voice chat tab open. Each value extends the previous one with the events that
step is supposed to add, so the checks pin down _when_ each event fires, not just
that it eventually does.
-}
fromJsAfterAdminOpensVoiceChat : List String
fromJsAfterAdminOpensVoiceChat =
    [ fromJs_GotMediaDevices ]


fromJsAfterUserOpensVoiceChat : List String
fromJsAfterUserOpensVoiceChat =
    fromJsAfterAdminOpensVoiceChat ++ [ fromJs_GotMediaDevices ]


{-| Assert the exact ordered list of `voice_chat_from_js` payloads produced so
far equals `expected`. Placed at each step so the prefix is pinned down as it
grows rather than only at the end.
-}
checkVoiceChatFromJsEvents : List String -> T.Data FrontendModel BackendModel2 -> Result String ()
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


voiceChatFromJsPayloads : T.Data FrontendModel BackendModel2 -> List String
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


checkNoNotification : String -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
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


{-| Like `connectTwoUsersAndJoinNewGuild` but two more people join the guild: a third user who
can also join games, and a fourth who can watch them.
-}
connectFourUsersAndJoinNewGuild :
    { width : Int, height : Int }
    ->
        (T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
         -> T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
         -> T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
         -> T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
         -> List (T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2)
        )
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
connectFourUsersAndJoinNewGuild windowSize continueFunc =
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
                        Just inviteUrl ->
                            [ joinGuildFromInvite
                                inviteUrl
                                windowSize
                                sessionId1
                                userEmail
                                "Stevie Steve"
                                (\userA ->
                                    [ joinGuildFromInvite
                                        inviteUrl
                                        windowSize
                                        sessionId2
                                        joeEmail
                                        "Joe"
                                        (\userB ->
                                            [ joinGuildFromInvite
                                                inviteUrl
                                                windowSize
                                                sessionId4
                                                wandaEmail
                                                "Wanda"
                                                (\userC ->
                                                    [ admin.click 100 (Dom.id "guild_openChannel_0")
                                                    , T.group (continueFunc admin userA userB userC)
                                                    ]
                                                )
                                            ]
                                        )
                                    ]
                                )
                            ]

                        Nothing ->
                            [ T.checkState 0 (\_ -> Err "Clipboard text not found") ]
                )
            ]
        )


{-| Connect a brand new user and have them join an existing guild via an invite link, ending up
viewing the guild's first channel.
-}
joinGuildFromInvite :
    String
    -> { width : Int, height : Int }
    -> SessionId
    -> EmailAddress
    -> String
    ->
        (T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
         -> List (T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2)
        )
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
joinGuildFromInvite inviteUrl windowSize sessionId email name continueFunc =
    T.connectFrontend
        100
        sessionId
        (dropPrefix Env.domain inviteUrl)
        windowSize
        (\user ->
            [ T.andThen
                10
                (\data -> [ user.portEvent 0 "load_startup_data_from_js" (startupDataJson data.time firefoxDesktop) ])
            , handleLoginFromLoginPage email user
            , user.input 100 (Dom.id "loginForm_name") name
            , user.click 100 (Dom.id "loginForm_submit")
            , user.click 100 (Dom.id "guild_openChannel_0")
            , T.group (continueFunc user)
            ]
        )


connectTwoUsersAndJoinNewGuild :
    { width : Int, height : Int }
    ->
        (T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
         -> T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
         -> List (T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2)
        )
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
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
                                    [ T.andThen
                                        10
                                        (\data2 -> [ user.portEvent 10 "load_startup_data_from_js" (startupDataJson data2.time firefoxDesktop) ])
                                    , handleLoginFromLoginPage userEmail user
                                    , user.input 100 (Dom.id "loginForm_name") "Stevie Steve"
                                    , user.click 100 (Dom.id "loginForm_submit")
                                    , user.click 100 (Dom.id "guild_openChannel_0")
                                    , enableNotifications False user
                                    , checkNotification "Success!" "Push notifications enabled"
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
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> DelayInMs
    -> Maybe HtmlId
    -> Maybe Range
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
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


{-| Sent from js when the text selection changes. The message input draws the selection highlight
itself (the textarea drawn on top of the rich text has a transparent one) so this is what makes text
actually look selected in a test.
-}
selectionEvent :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> DelayInMs
    -> HtmlId
    -> Range
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
selectionEvent user delayInMs htmlId selection =
    user.portEvent
        delayInMs
        "selection_changed_from_js"
        (Json.Encode.object
            [ ( "id", Json.Encode.string (Dom.idToString htmlId) )
            , ( "selectionStart", Json.Encode.int selection.start )
            , ( "selectionEnd", Json.Encode.int selection.end )
            , ( "selectionDirection", Json.Encode.string "forward" )
            ]
        )


writeMessage : T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2 -> DelayInMs -> String -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
writeMessage user delayInMs text =
    T.group
        [ focusEvent user delayInMs (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
        , user.click 100 (Dom.id "channel_textinput")
        , user.input 100 (Dom.id "channel_textinput") text
        , user.keyDown 100 (Dom.id "channel_textinput") "Enter" []
        , focusEvent user 100 Nothing Nothing
        ]


writeMessageMobile : T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2 -> String -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
writeMessageMobile user text =
    T.group
        [ user.input 100 (Dom.id "channel_textinput") text
        , user.click 100 (Dom.id "messageMenu_channelInput_sendMessage")
        ]


{-| Presses the up arrow while the channel text input is empty. This should start
editing the most recent message that the user wrote (pre-filled with its current
content), which we then change to `editedText` and submit by pressing enter.

Works the same way for guild channels, DMs, threads and Discord channels since they
all share the `channel_textinput` and `editMessageTextInput` ids.

-}
editMostRecentMessageViaArrowUp :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> String
    -> String
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
editMostRecentMessageViaArrowUp user originalText editedText =
    T.collapsableGroup
        "Edit most recent message by pressing up arrow"
        [ -- No message is being edited yet.
          user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "editMessageTextInput" ])

        -- Pressing up in the empty channel input opens the edit box for the most recent message we wrote.
        , user.keyDown 100 (Dom.id "channel_textinput") "ArrowUp" []
        , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "editMessageTextInput" ])

        -- The edit box is pre-filled with the existing message content.
        , user.checkView
            100
            (Test.Html.Query.has
                [ Test.Html.Selector.id "editMessageTextInput"
                , Test.Html.Selector.attribute (Html.Attributes.value originalText)
                ]
            )
        , user.input 200 (Dom.id "editMessageTextInput") editedText
        , user.keyDown 100 (Dom.id "editMessageTextInput") "Enter" []

        -- The edit box closes and the message now shows the edited text.
        , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "editMessageTextInput" ])
        , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText editedText ])
        ]


createThread : T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2 -> Id ChannelMessageId -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
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
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> HtmlId
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
clickSpoiler user htmlId =
    T.group
        [ user.click 100 htmlId
        , user.checkView
            100
            (Test.Html.Query.hasNot [ Test.Html.Selector.attribute (Html.Attributes.id (Dom.idToString htmlId)) ])
        ]


scrollToTop :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
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
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
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


scrollToBottom :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
scrollToBottom user =
    user.custom
        100
        Pages.Guild.conversationContainerId
        "scroll"
        (Json.Encode.object
            [ ( "target"
              , Json.Encode.object
                    [ ( "scrollTop", Json.Encode.float (2000 - (desktopWindow.height - 40)) )
                    , ( "scrollHeight", Json.Encode.float 2000 )
                    , ( "clientHeight", Json.Encode.float (desktopWindow.height - 40) )
                    ]
              )
            ]
        )


hasExactText :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> List String
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
hasExactText user texts =
    user.checkView 100 (Test.Html.Query.has (List.map Test.Html.Selector.exactText texts))


hasText :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> List String
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
hasText user texts =
    user.checkView 100 (Test.Html.Query.has (List.map Test.Html.Selector.text texts))


hasNotExactText :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> List String
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
hasNotExactText user texts =
    user.checkView 100 (Test.Html.Query.hasNot (List.map Test.Html.Selector.exactText texts))


hasNotText :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> List String
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
hasNotText user texts =
    user.checkView 100 (Test.Html.Query.hasNot (List.map Test.Html.Selector.text texts))


noMissingMessages : DelayInMs -> T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2 -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
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


uploadImageAttachment :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
uploadImageAttachment user =
    T.group
        [ user.click 100 (Dom.id "messageMenu_channelInput_uploadFile")
        , T.backendUpdate
            100
            (Types.Rpc_GotFileUpload (FileStatus.fileHash "123123123") 1234 (Just (Coord.xy 128 128)))
        ]


{-| Uploads a non-image file. The reported image size is Nothing since the Rust
server only extracts image dimensions for files it can decode as an image.
-}
uploadNonImageAttachment :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
uploadNonImageAttachment user =
    T.group
        [ user.click 100 (Dom.id "messageMenu_channelInput_uploadFile")
        , T.backendUpdate
            100
            (Types.Rpc_GotFileUpload (FileStatus.fileHash "123123123") 1234 Nothing)
        ]


{-| Builds the actions for an inline media attachment end-to-end test. First a
plain attachment is posted and snapshotted, then a spoilered one which is hidden
behind a black box until the user clicks it to reveal the inline media element.
`tagName` is the element that should appear once visible ("video" or "audio").
-}
attachmentTestActions :
    { tagName : String
    , plainSnapshot : String
    , spoileredSnapshot : String
    , revealedSnapshot : String
    }
    -> T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> List (T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2)
attachmentTestActions options admin =
    [ -- The attachment renders inline in a media element instead of an "open in
      -- new tab" link, so it can be played without leaving the page.
      uploadNonImageAttachment admin
    , focusEvent admin 1000 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
    , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
    , admin.checkView
        100
        (Test.Html.Query.has
            [ Test.Html.Selector.id "spoiler_1_file_1"
            , Test.Html.Selector.tag options.tagName
            ]
        )
    , tallSnapshot admin 100 { name = options.plainSnapshot }

    -- A spoilered attachment (second message) stays hidden behind a black box,
    -- so the media element isn't rendered yet.
    , uploadNonImageAttachment admin
    , admin.click 100 (Dom.id "fileStatus_spoiler_1")
    , focusEvent admin 1000 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
    , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
    , tallSnapshot admin 100 { name = options.spoileredSnapshot }

    -- Clicking the spoiler reveals the inline media element.
    , clickSpoiler admin (Dom.id "spoiler_2_0")
    , admin.checkView
        100
        (Test.Html.Query.has
            [ Test.Html.Selector.id "spoiler_2_file_1"
            , Test.Html.Selector.tag options.tagName
            ]
        )
    , tallSnapshot admin 100 { name = options.revealedSnapshot }
    ]


tallSnapshot :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> DelayInMs
    -> { name : String }
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
tallSnapshot user delayInMs name =
    T.andThen
        0
        (\data ->
            case SeqDict.get user.clientId data.frontends |> Maybe.map Audio.userModel of
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
            [ T.andThen
                10
                (\data -> [ userA.portEvent 10 "load_startup_data_from_js" (startupDataJson data.time firefoxDesktop) ])
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
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
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
            [ T.andThen
                10
                (\data -> [ userB.portEvent 10 "load_startup_data_from_js" (startupDataJson data.time firefoxDesktop) ])
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


{-| Logs a brand new at-chat user in (in a fresh session) and links a _second_
Discord account to that user, distinct from the one linked by
`linkDiscordAndLogin`. Unlike `linkSecondDiscordAccount`, this represents a
genuinely different at-chat user rather than a second Discord account on the
already-logged-in user. The second Discord account shares the same guild
membership as the first because the provided ready data is reused with the user
id substituted.
-}
linkDiscordAndLoginSecondUser :
    SessionId
    -> String
    -> EmailAddress
    -> String
    -> String
    -> (T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2 -> List (T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2))
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
linkDiscordAndLoginSecondUser sessionId name emailAddress discordOp0Ready discordOp0ReadySupplemental continueWith =
    let
        secondAuth : Discord.UserAuth
        secondAuth =
            { discordUserAuth | token = secondDiscordToken }

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
            [ T.andThen
                10
                (\data -> [ userB.portEvent 10 "load_startup_data_from_js" (startupDataJson data.time firefoxDesktop) ])
            , handleLoginFromLoginPage emailAddress userB
            , userB.input 100 (Dom.id "loginForm_name") name
            , userB.click 100 (Dom.id "loginForm_submit")
            , T.andThen
                120
                (\data ->
                    case findUntouchedBackendWebsocket data of
                        Just connection ->
                            [ T.websocketSendString 100 connection """{"t":null,"s":null,"op":10,"d":{"heartbeat_interval":41250,"_trace":["[\\"gateway-prd-arm-us-east1-d-swb5\\",{\\"micros\\":0.0}]"]}}""" ]

                        Nothing ->
                            [ T.checkState 0 (\_ -> Err "Couldn't find the second user's newly opened Discord websocket") ]
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
                            [ T.checkState 0 (\_ -> Err "The second user's Discord websocket didn't send OP2 with the expected token") ]
                )
            , T.group (continueWith userB)
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
                        """{"id":"184437096813953035","username":"at28727","avatar":"7c40cb63ea11096169c5a4dcb5825a3d","discriminator":"0","public_flags":0,"flags":0,"banner":null,"accent_color":null,"global_name":"AT2","avatar_decoration_data":null,"collectibles":null,"display_name_styles":null,"banner_color":null,"clan":null,"primary_guild":null,"mfa_enabled":false,"locale":"en-US","premium_type":0,"email":"a@a.aa","verified":true,"phone":null,"nsfw_allowed":null,"linked_users":[],"bio":"","authenticator_types":[],"age_verification_status":1}"""

                else if List.Extra.count (\a -> a == ( "Authorization", secondDiscordToken )) headers == 1 && body == Nothing then
                    StringHttpResponse
                        { url = url, statusCode = 200, statusText = "OK", headers = Dict.empty }
                        ("""{"id":\"""" ++ secondDiscordUserIdString ++ """","username":"at-second","avatar":null,"discriminator":"0","public_flags":0,"flags":0,"banner":null,"accent_color":null,"global_name":"AT Second","avatar_decoration_data":null,"collectibles":null,"display_name_styles":null,"banner_color":null,"clan":null,"primary_guild":null,"mfa_enabled":false,"locale":"en-US","premium_type":0,"email":"second@a.a","verified":true,"phone":null,"nsfw_allowed":null,"linked_users":[],"bio":"","authenticator_types":[],"age_verification_status":1}""")

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

            ( "GET", [ "discord.com", "api", "v9", "channels", channelId, endpoint ] ) ->
                if String.startsWith "messages?" endpoint then
                    StringHttpResponse
                        { url = url, statusCode = 200, statusText = "OK", headers = Dict.empty }
                        (discordChannelHistory channelId)

                else
                    UnhandledHttpRequest

            ( "PATCH", [ "discord.com", "api", "v9", "channels", _, "messages", _ ] ) ->
                StringHttpResponse { url = url, statusCode = 200, statusText = "OK", headers = Dict.empty } ""

            ( "DELETE", [ "discord.com", "api", "v9", "channels", _, "messages", _ ] ) ->
                StringHttpResponse { url = url, statusCode = 204, statusText = "OK", headers = Dict.empty } ""

            ( "PUT", [ "discord.com", "api", "v9", "channels", _, "messages", _, "reactions", _, "@me" ] ) ->
                StringHttpResponse { url = url, statusCode = 204, statusText = "OK", headers = Dict.empty } ""

            ( "DELETE", [ "discord.com", "api", "v9", "channels", _, "messages", _, "reactions", _, "@me" ] ) ->
                StringHttpResponse { url = url, statusCode = 204, statusText = "OK", headers = Dict.empty } ""

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

            [ "upload-url" ] ->
                case currentRequest.body of
                    T.JsonBody json ->
                        case Codec.decodeValue FileStatus.uploadUrlCodec json of
                            Ok request ->
                                -- Check if we are trying to upload a Discord standard sticker. We don't want those loaded by automated systems as they are copyrighted material
                                if String.contains "796138864933863456" request.url then
                                    UnhandledHttpRequest

                                else
                                    httpBasic
                                        currentRequest.url
                                        200
                                        (Codec.encodeToString
                                            0
                                            FileStatus.uploadResponseCodec
                                            { fileHash = FileStatus.fileHash request.url
                                            , videoMetadata = Nothing
                                            , imageMetadata =
                                                { imageSize = Coord.xy 128 128
                                                , orientation = Nothing
                                                , gpsLocation = Nothing
                                                , cameraOwner = Nothing
                                                , exposureTime = Nothing
                                                , fNumber = Nothing
                                                , focalLength = Nothing
                                                , isoSpeedRating = Nothing
                                                , make = Nothing
                                                , model = Nothing
                                                , software = Nothing
                                                , userComment = Nothing
                                                }
                                                    |> Just
                                            }
                                        )

                            Err _ ->
                                httpBasic currentRequest.url 500 ""

                    _ ->
                        httpBasic currentRequest.url 500 ""

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
    -> T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> List (T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2)
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
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
                    , attacker.input 100 (Dom.id "loginForm_name") "Attacker"
                    , attacker.click 100 (Dom.id "loginForm_submit")
                    , attacker.update 100 (Audio.userMsg Types.EnableToFrontendLogging)
                    ]
                , T.group actions
                , attacker.checkModel
                    100
                    (\model ->
                        case Audio.userModel model of
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
        CheckLoginResponse _ _ ->
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

                Local_SendMessage _ _ _ _ _ _ _ ->
                    True

                Local_Discord_SendMessage _ _ _ _ _ _ ->
                    True

                Local_NewChannel _ _ _ _ ->
                    True

                Local_EditChannel _ _ _ _ ->
                    True

                Local_DeleteChannel _ _ ->
                    True

                Local_EditGuildName _ _ ->
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

                Local_SendEditMessage _ _ _ _ _ _ ->
                    True

                Local_Discord_SendEditGuildMessage _ _ _ _ _ _ _ ->
                    True

                Local_Discord_SendEditDmMessage _ _ _ _ _ ->
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

                        ViewDmThread _ _ ->
                            False

                        ViewDiscordDm _ _ ->
                            True

                        ViewChannel data _ ->
                            data.guildId == legitGuildId

                        ViewChannelThread _ _ ->
                            True

                        ViewDiscordChannel _ _ ->
                            True

                        ViewDiscordChannelThread _ _ ->
                            True

                        StopViewingChannel ->
                            False

                        -- The overview response only contains the Discord users behind
                        -- the unread messages of whoever requested it, so there's nothing
                        -- here the attacker shouldn't get.
                        ViewOverview _ ->
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

                Local_SetEmailNotifications _ ->
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

                Local_SetEmojiSkinTone _ ->
                    False

                Local_VoiceChatChange _ ->
                    True

                Local_AddCustomEmojisToUser _ ->
                    False

                Local_Game _ _ ->
                    True

                Local_Drawing _ _ _ ->
                    True

                Local_SetMuteChannel _ _ _ ->
                    True

                Local_SetMuteThread _ _ _ _ ->
                    True

                Local_SetMuteDiscordChannel _ _ _ _ ->
                    True

                Local_SetMuteDiscordThread _ _ _ _ _ ->
                    True

                Local_SetMuteGuild _ _ ->
                    True

                Local_SetMuteDiscordGuild _ _ _ ->
                    True

        ChangeBroadcast localMsg ->
            case localMsg of
                Types.LocalChange _ _ ->
                    True

                Types.ServerChange serverChange ->
                    case serverChange of
                        Types.Server_SendMessage _ _ _ _ _ _ _ _ ->
                            True

                        --RichText.toString SeqDict.empty message |> String.contains "sensitive"
                        Types.Server_Discord_SendMessage _ _ _ _ _ _ _ ->
                            True

                        Types.Server_NewChannel _ _ _ _ ->
                            True

                        Types.Server_EditChannel _ _ _ _ ->
                            True

                        Types.Server_DeleteChannel _ _ ->
                            True

                        Types.Server_EditGuildName _ _ ->
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

                        Types.Server_DiscordForumPostDeleted _ _ _ ->
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

                        Types.Server_CurrentlyViewing _ _ _ ->
                            True

                        Types.Server_ClientDisconnected _ _ ->
                            True

                        Types.Server_TextEditor _ ->
                            True

                        Types.Server_LinkDiscordUser _ _ ->
                            False

                        Types.Server_UnlinkDiscordUser _ ->
                            True

                        Types.Server_DiscordChannelCreated _ _ _ _ _ _ ->
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

                        Types.Server_DiscordUpdateChannel _ _ _ _ _ ->
                            True

                        Types.Server_DiscordUpdateRole _ _ _ ->
                            True

                        Types.Server_DiscordUpdateGuildCustomEmojis _ _ ->
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

                        Types.Server_Game _ _ _ ->
                            True

                        Types.Server_SetGuildIcon _ _ ->
                            True

                        Types.Server_Drawing _ _ _ _ ->
                            True

                        Types.Server_SetMuteChannel _ _ _ ->
                            True

                        Types.Server_SetMuteThread _ _ _ _ ->
                            True

                        Types.Server_SetMuteDiscordChannel _ _ _ ->
                            True

                        Types.Server_SetMuteDiscordThread _ _ _ _ ->
                            True

                        Types.Server_SetMuteGuild _ _ ->
                            True

                        Types.Server_SetMuteDiscordGuild _ _ ->
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

        ExportChannelResponse _ ->
            True


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
    , ProfilePictureEditorToBackend (ImageEditor.ChangeUserAvatarRequest (Just (FileStatus.FileHash "fake-hash")))
    , ProfilePictureEditorToBackend (ImageEditor.ChangeGuildIconRequest (Id.fromInt 0) (Just (FileStatus.FileHash "fake-hash")))
    , AdminDataRequest Nothing
    , GetPublicGoMatchRequest (SecretId.fromString "attacker-public-id")
    , ExportChannelRequest (ExportChannel_Guild legitGuildId (Id.fromInt 0))
    , ExportChannelRequest
        (ExportChannel_Discord
            (Discord.idFromUInt64 (Unsafe.uint64 "184437096813953035"))
            (Discord.idFromUInt64 (Unsafe.uint64 "705745250815311942"))
            (Discord.idFromUInt64 (Unsafe.uint64 "1072828564317159465"))
        )
    , ExportChannelRequest (ExportChannel_Dm (Id.fromInt 1))
    , ExportChannelRequest
        (ExportChannel_DiscordDm
            (Discord.idFromUInt64 (Unsafe.uint64 "184437096813953035"))
            (Discord.idFromUInt64 (Unsafe.uint64 "1215077285749858324"))
        )
    , LogOutRequest sessionId0Hash
    , LogOutRequest sessionId1Hash
    , LogOutRequest sessionId2Hash
    , LogOutRequest sessionId4Hash
    , LoginWithRecoveryPasswordRequest InitialLoadRequested_None "123" UserAgent.init
    , -- Make sure this one is last. It actually logs out the attacker
      LogOutRequest sessionIdAttackerHash
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
    , Local_Discord_SendEditDmMessage messageTime Time.utc discordDmData (Id.fromInt 0) normalText
    , Local_Discord_SendEditGuildMessage messageTime Time.utc discordUserId discordGuildId discordChannelId threadRouteWithMessage normalText
    , Local_Discord_SendMessage messageTime Time.utc discordGuildOrDmId_guild normalText threadRouteWithMaybeMessage SeqDict.empty
    , Local_Discord_SendMessage messageTime Time.utc discordGuildOrDmId_dm normalText threadRouteWithMaybeMessage SeqDict.empty
    , Local_EditChannel legitGuildId channelId (Unsafe.channelName "hacked") ChannelDescription.empty
    , Local_EditGuildName legitGuildId (Unsafe.guildName "hacked")
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
    , Local_RegisterPushSubscription (Time.millisToPosix 9) (GotSubscribeData { endpoint = domain, expirationTime = Nothing, keys = { auth = "auth", p256dh = "p256dh" } })
    , Local_RegisterPushSubscription (Time.millisToPosix 9) (SubscribeJsException "")
    , Local_RemoveReactionEmoji guildOrDmId_guild threadRouteWithMessage emoji
    , Local_SendEditMessage messageTime Time.utc (GuildOrDmId_Dm normalUserId) threadRouteWithMessage normalText SeqDict.empty
    , Local_SendMessage messageTime Time.utc (GuildOrDmId_Guild legitGuildId channelId) normalText threadRouteWithMaybeMessage SeqDict.empty []
    , Local_RemoveReactionEmoji guildOrDmId_dm threadRouteWithMessage emoji
    , Local_SendEditMessage messageTime Time.utc (GuildOrDmId_Dm normalUserId) threadRouteWithMessage normalText SeqDict.empty
    , Local_SendMessage messageTime Time.utc (GuildOrDmId_Dm normalUserId) normalText threadRouteWithMaybeMessage SeqDict.empty [ EmojiOrCustomEmoji_Emoji Emoji.heart ]
    , Local_SetDiscordGuildNotificationLevel discordUserId discordGuildId User.NotifyOnEveryMessage
    , Local_SetDomainWhitelist True (Domain "example.com")
    , Local_SetEmojiSkinTone (Just Emoji.SkinTone1)
    , Local_SetGuildNotificationLevel legitGuildId User.NotifyOnEveryMessage
    , Local_SetLastViewed guildOrDmId_guild threadRouteWithMessage
    , Local_SetLastViewed guildOrDmId_dm threadRouteWithMessage
    , Local_SetMuteChannel legitGuildId channelId MuteSettings.IsMuted
    , Local_SetMuteDiscordChannel discordUserId discordGuildId discordChannelId MuteSettings.IsMuted
    , Local_SetMuteDiscordThread discordUserId discordGuildId discordChannelId (Id.fromInt 0) MuteSettings.IsMuted
    , Local_SetMuteThread legitGuildId channelId (Id.fromInt 0) MuteSettings.IsMuted
    , Local_SetName (Unsafe.personName "hacked")
    , Local_SetNotificationMode NoNotifications
    , Local_SetEmailNotifications User.NotifyMeWhenMentioned
    , Local_StartReloadingDiscordUser messageTime discordUserId
    , Local_TextEditor TextEditor.Local_Reset
    , Local_UnlinkDiscordUser discordUserId
    , Local_StartReloadingDiscordUser messageTime discordUserId
    , Local_LinkDiscordAcknowledgementIsChecked True
    , Local_SetDomainWhitelist False brokenDomain
    , Local_SetDomainWhitelist True brokenDomain
    , Local_SetEmojiSkinTone Nothing
    , Local_SetEmojiSkinTone (Just SkinTone5)
    , Local_AddCustomEmojisToUser (NonemptySet.fromNonemptyList (Nonempty (Id.fromInt 0) []))
    , Local_VoiceChatChange (Call.Local_Leave startTime)
    , Local_Game
        (GuildOrDmId_Dm Broadcast.adminUserId)
        (Game.LocalChange_Go
            (Id.fromInt 0)
            (Go.StartMatch
                (Time.millisToPosix 0)
                { width = Go.boardSize9
                , height = Go.boardSize9
                , handicap = 0
                , komiHalfPoints = Go.KomiHalfPoints 2
                , timeControl = Nothing
                , createdBy = normalUserId
                , gameCreatorPlayingAs = Go.Black
                }
            )
        )
    , Local_Game
        (GuildOrDmId_Dm Broadcast.adminUserId)
        (Game.CreatePublicLink (Id.fromInt 0) EmptyPlaceholder)
    , Local_Game
        (GuildOrDmId_Guild legitGuildId channelId)
        (Game.LocalChange_WordSpellingGame
            (Id.fromInt 0)
            (WordSpellingGame.Action
                { userId = normalUserId, time = messageTime, change = WordSpellingGame.JoinGame }
            )
        )
    , Local_DeleteInviteLink legitGuildId (SecretId.fromString "123")
    , Local_Drawing
        guildOrDmId_guild
        (Drawing.MessageAnchor threadRouteWithMessage Drawing.UserIconAnchor)
        (Drawing.StartStroke ( 0, 0 ))
    , Local_SetMuteDiscordGuild discordUserId discordGuildId MuteSettings.IsMuted
    , Local_SetMuteGuild legitGuildId MuteSettings.IsMuted
    ]


{-| Id of a private Discord channel in the Bot Test guild (705745250815311942).
-}
privateDiscordChannelId : Discord.Id Discord.ChannelId
privateDiscordChannelId =
    Unsafe.uint64 "1500000000000000777" |> Discord.idFromUInt64


{-| A CHANNEL\_CREATE gateway event for a private channel in the Bot Test guild.
The @everyone role (whose id equals the guild id) is denied View Channel
(permission bit 10 = 1024) and only the admin's linked Discord account
(184437096813953035) is granted it through a member overwrite, so no other guild
member should be able to see or interact with the channel.
-}
privateDiscordChannelCreateEvent : String
privateDiscordChannelCreateEvent =
    """{"t":"CHANNEL_CREATE","s":90,"op":0,"d":{"id":"1500000000000000777","type":0,"guild_id":"705745250815311942","name":"secret-channel","position":10,"topic":null,"parent_id":null,"nsfw":false,"last_message_id":null,"permission_overwrites":[{"id":"705745250815311942","type":0,"allow":"0","deny":"1024"},{"id":"184437096813953035","type":1,"allow":"1024","deny":"0"}]}}"""


{-| Id of a channel in the Bot Test guild (705745250815311942) that starts out
public and is later made private through a CHANNEL\_UPDATE event.
-}
regularDiscordChannelId : Discord.Id Discord.ChannelId
regularDiscordChannelId =
    Unsafe.uint64 "1500000000000000778" |> Discord.idFromUInt64


{-| A CHANNEL\_CREATE gateway event for a public channel in the Bot Test guild.
The @everyone role (whose id equals the guild id) is explicitly allowed View
Channel (permission bit 10 = 1024), so every guild member can see it.
-}
regularDiscordChannelCreateEvent : String
regularDiscordChannelCreateEvent =
    """{"t":"CHANNEL_CREATE","s":91,"op":0,"d":{"id":"1500000000000000778","type":0,"guild_id":"705745250815311942","name":"regular-channel","position":11,"topic":null,"parent_id":null,"nsfw":false,"last_message_id":null,"permission_overwrites":[{"id":"705745250815311942","type":0,"allow":"1024","deny":"0"}]}}"""


{-| A CHANNEL\_UPDATE gateway event that makes the previously public
`regularDiscordChannelId` private: the @everyone overwrite now denies View
Channel (permission bit 10 = 1024) instead of allowing it. Discord sends a
CHANNEL\_UPDATE whenever a channel's permission overwrites change, so the backend
must apply the new overwrites; otherwise a member would keep seeing a channel
they've just been locked out of.
-}
regularDiscordChannelBecomesPrivateEvent : String
regularDiscordChannelBecomesPrivateEvent =
    """{"t":"CHANNEL_UPDATE","s":92,"op":0,"d":{"id":"1500000000000000778","type":0,"guild_id":"705745250815311942","name":"regular-channel","position":11,"topic":null,"parent_id":null,"nsfw":false,"last_message_id":null,"permission_overwrites":[{"id":"705745250815311942","type":0,"allow":"0","deny":"1024"}]}}"""


{-| A MESSAGE\_CREATE gateway event authored by the admin's Discord account
(184437096813953035) in the private channel, carrying the given sequence number
and content. Used to simulate the admin writing ordinary messages that no other
guild member should be able to read.
-}
privateDiscordChannelMessageEvent : Int -> String -> String
privateDiscordChannelMessageEvent sequence content =
    """{"t":"MESSAGE_CREATE","s":"""
        ++ String.fromInt sequence
        ++ ""","op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-29T00:00:00.000000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":[],"premium_since":null,"pending":false,"nick":null,"mute":false,"joined_at":"2020-05-01T11:39:39.915000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":\""""
        -- Built by string concatenation (not integer arithmetic) so the 19-digit
        -- snowflake keeps full precision.
        ++ ("1500000000000010" ++ String.padLeft 3 '0' (String.fromInt sequence))
        ++ """","flags":0,"embeds":[],"edited_timestamp":null,"content":\""""
        ++ content
        ++ """","components":[],"channel_type":0,"channel_id":"1500000000000000777","author":{"username":"at28727","public_flags":0,"primary_guild":null,"id":"184437096813953035","global_name":"AT2","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"7c40cb63ea11096169c5a4dcb5825a3d"},"attachments":[],"guild_id":"705745250815311942"}}"""


{-| LocalChanges an attacker might send trying to read from or modify the private
Discord channel they have no access to. The attacker acts as their own linked
Discord account (555...), and also tries impersonating the admin's account
(184...) for the read/write vectors.
-}
attackerPrivateDiscordChannelChanges : List LocalChange
attackerPrivateDiscordChannelChanges =
    let
        attackerDiscordUserId : Discord.Id Discord.UserId
        attackerDiscordUserId =
            secondDiscordUserId

        adminDiscordUserId : Discord.Id Discord.UserId
        adminDiscordUserId =
            currentDiscordUserId

        guildId : Discord.Id Discord.GuildId
        guildId =
            botTestGuild

        messageTime : Time.Posix
        messageTime =
            Time.millisToPosix 99999

        hackedText : NonemptyString
        hackedText =
            NonemptyString 'h' "acked"

        threadRouteWithMessage : ThreadRouteWithMessage
        threadRouteWithMessage =
            NoThreadWithMessage (Id.fromInt 0)

        threadRouteWithMaybeMessage : ThreadRouteWithMaybeMessage
        threadRouteWithMaybeMessage =
            NoThreadWithMaybeMessage (Just (Id.fromInt 0))

        emoji : EmojiOrCustomEmoji
        emoji =
            EmojiOrCustomEmoji_Emoji (Emoji.UnicodeEmoji "👍")

        asUser : Discord.Id Discord.UserId -> DiscordGuildOrDmId
        asUser discordUserId =
            DiscordGuildOrDmId_Guild discordUserId guildId privateDiscordChannelId

        anyAsUser : Discord.Id Discord.UserId -> AnyGuildOrDmId
        anyAsUser discordUserId =
            DiscordGuildOrDmId (asUser discordUserId)
    in
    [ -- Read attempts (as the attacker, and impersonating the admin).
      Local_Discord_LoadChannelMessages (asUser attackerDiscordUserId) (Id.fromInt 0) EmptyPlaceholder
    , Local_Discord_LoadChannelMessages (asUser adminDiscordUserId) (Id.fromInt 0) EmptyPlaceholder
    , Local_Discord_LoadThreadMessages (asUser attackerDiscordUserId) (Id.fromInt 0) (Id.fromInt 0) EmptyPlaceholder
    , Local_SetLastViewed (anyAsUser attackerDiscordUserId) threadRouteWithMessage

    -- Write/modify attempts.
    , Local_Discord_SendMessage messageTime Time.utc (asUser attackerDiscordUserId) hackedText threadRouteWithMaybeMessage SeqDict.empty
    , Local_Discord_SendMessage messageTime Time.utc (asUser adminDiscordUserId) hackedText threadRouteWithMaybeMessage SeqDict.empty
    , Local_Discord_SendEditGuildMessage messageTime Time.utc attackerDiscordUserId guildId privateDiscordChannelId threadRouteWithMessage hackedText
    , Local_Discord_SendEditGuildMessage messageTime Time.utc adminDiscordUserId guildId privateDiscordChannelId threadRouteWithMessage hackedText
    , Local_DeleteMessage (anyAsUser attackerDiscordUserId) threadRouteWithMessage
    , Local_DeleteMessage (anyAsUser adminDiscordUserId) threadRouteWithMessage
    , Local_AddReactionEmoji (anyAsUser attackerDiscordUserId) threadRouteWithMessage emoji
    , Local_RemoveReactionEmoji (anyAsUser attackerDiscordUserId) threadRouteWithMessage emoji
    , Local_MemberTyping messageTime ( anyAsUser attackerDiscordUserId, NoThread )
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


{-| What Discord answers with when the messages of a channel are loaded. Newest message
first, like the real API returns them. Channels other than the Bot Test guild's channel A
and the threads hanging off its messages are empty.
-}
discordChannelHistory : String -> String
discordChannelHistory channelId =
    if channelId == botTestGuild_ChannelAString then
        botTestGuildChannelAHistory

    else if channelId == "1533000000000000001" then
        -- The thread started from "Old message". Discord posts a thread starter message
        -- (type 21) as the first message of a thread that was started from a message.
        """[
    {"id":"1533096100000000000","channel_id":"1533000000000000001","content":"Message in old message thread","timestamp":"2026-04-02T09:02:35.284000+00:00","edited_timestamp":null,"tts":false,"mention_everyone":false,"mention_roles":[],"attachments":[],"embeds":[],"pinned":false,"type":0,"flags":0,"author":{"username":"at0232","public_flags":0,"id":"161098476632014848","global_name":"AT","discriminator":"0","avatar":"3d7b1aa7b5149fe06971b6dedf682d82"}},
    {"id":"1533096050000000000","channel_id":"1533000000000000001","content":"","timestamp":"2026-04-02T09:02:31.114000+00:00","edited_timestamp":null,"tts":false,"mention_everyone":false,"mention_roles":[],"attachments":[],"embeds":[],"pinned":false,"type":21,"flags":0,"message_reference":{"type":0,"message_id":"1533000000000000001","guild_id":"705745250815311942","channel_id":"1072828564317159465"},"author":{"username":"at0232","public_flags":0,"id":"161098476632014848","global_name":"AT","discriminator":"0","avatar":"3d7b1aa7b5149fe06971b6dedf682d82"}}
]"""

    else if channelId == "1533000000000000002" then
        """[
    {"id":"1533096200000000000","channel_id":"1533000000000000002","content":"Message in stand-alone thread","timestamp":"2026-03-26T12:10:40.000000+00:00","edited_timestamp":null,"tts":false,"mention_everyone":false,"mention_roles":[],"attachments":[],"embeds":[],"pinned":false,"type":0,"flags":0,"author":{"username":"at0232","public_flags":0,"id":"161098476632014848","global_name":"AT","discriminator":"0","avatar":"3d7b1aa7b5149fe06971b6dedf682d82"}}
]"""

    else if channelId == "1533000000000000003" then
        """[
    {"id":"1533096300000000000","channel_id":"1533000000000000003","content":"Message in archived thread","timestamp":"2026-03-26T12:11:30.000000+00:00","edited_timestamp":null,"tts":false,"mention_everyone":false,"mention_roles":[],"attachments":[],"embeds":[],"pinned":false,"type":0,"flags":0,"author":{"username":"at0232","public_flags":0,"id":"161098476632014848","global_name":"AT","discriminator":"0","avatar":"3d7b1aa7b5149fe06971b6dedf682d82"}}
]"""

    else
        "[]"


{-| What Discord answers with when the Bot Test guild's channel A gets reloaded from the
admin page. Newest message first, like the real API returns them.

Along with two ordinary messages it contains the two kinds of thread created message
(type 18) Discord posts in a channel: one for a stand-alone thread (its own id is the
thread's id) and one for a thread started from "Old message" (its message\_reference points
at the thread, which reuses that message's id).

Every message that a thread hangs off of has the has-thread flag (32) set. "Hello from
history" has an archived thread, which is just as visible in the flag as an active one.

-}
botTestGuildChannelAHistory : String
botTestGuildChannelAHistory =
    """[
    {"id":"1533096000000000000","channel_id":"1072828564317159465","content":"Thread from old message","timestamp":"2026-04-02T09:02:31.114000+00:00","edited_timestamp":null,"tts":false,"mention_everyone":false,"mention_roles":[],"attachments":[],"embeds":[],"pinned":false,"type":18,"flags":32,"message_reference":{"type":0,"guild_id":"705745250815311942","channel_id":"1533000000000000001"},"author":{"username":"at0232","public_flags":0,"id":"161098476632014848","global_name":"AT","discriminator":"0","avatar":"3d7b1aa7b5149fe06971b6dedf682d82"}},
    {"id":"1533000000000000003","channel_id":"1072828564317159465","content":"Hello from history","timestamp":"2026-03-26T12:11:00.000000+00:00","edited_timestamp":null,"tts":false,"mention_everyone":false,"mention_roles":[],"attachments":[],"embeds":[],"pinned":false,"type":0,"flags":32,"author":{"username":"at0232","public_flags":0,"id":"161098476632014848","global_name":"AT","discriminator":"0","avatar":"3d7b1aa7b5149fe06971b6dedf682d82"}},
    {"id":"1533000000000000002","channel_id":"1072828564317159465","content":"Stand-alone thread","timestamp":"2026-03-26T12:10:30.000000+00:00","edited_timestamp":null,"tts":false,"mention_everyone":false,"mention_roles":[],"attachments":[],"embeds":[],"pinned":false,"type":18,"flags":32,"message_reference":{"type":0,"guild_id":"705745250815311942","channel_id":"1533000000000000002"},"author":{"username":"at0232","public_flags":0,"id":"161098476632014848","global_name":"AT","discriminator":"0","avatar":"3d7b1aa7b5149fe06971b6dedf682d82"}},
    {"id":"1533000000000000001","channel_id":"1072828564317159465","content":"Old message","timestamp":"2026-03-26T12:10:08.752000+00:00","edited_timestamp":null,"tts":false,"mention_everyone":false,"mention_roles":[],"attachments":[],"embeds":[],"pinned":false,"type":0,"flags":32,"author":{"username":"at0232","public_flags":0,"id":"161098476632014848","global_name":"AT","discriminator":"0","avatar":"3d7b1aa7b5149fe06971b6dedf682d82"}}
]"""


botTestGuild : Discord.Id Discord.GuildId
botTestGuild =
    Unsafe.uint64 botTestGuildString |> Discord.idFromUInt64


botTestGuildString : String
botTestGuildString =
    "705745250815311942"


botTestGuild_ChannelA : Discord.Id Discord.ChannelId
botTestGuild_ChannelA =
    Unsafe.uint64 botTestGuild_ChannelAString |> Discord.idFromUInt64


botTestGuild_ChannelAString : String
botTestGuild_ChannelAString =
    "1072828564317159465"


botTestGuild_ForumA : Discord.Id Discord.ChannelId
botTestGuild_ForumA =
    Unsafe.uint64 botTestGuild_ForumAString |> Discord.idFromUInt64


botTestGuild_ForumAString : String
botTestGuild_ForumAString =
    "1535645724761653309"


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
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> (T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2 -> List (T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2))
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
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
                                        [ T.andThen
                                            10
                                            (\data2 -> [ user.portEvent 10 "load_startup_data_from_js" (startupDataJson data2.time firefoxDesktop) ])
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


{-| Opens a DM with another user by clicking their name in the member column.
The column holds the "open DM" buttons and starts closed on both mobile and
desktop, so it has to be opened first. Opening it spends no time of its own, so
the overall timeline matches what a single click on the member cost before the
column became closable.
-}
openDm :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> DelayInMs
    -> String
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
openDm actions delay dmUserId =
    T.group
        [ actions.click delay (Dom.id "guild_showMembers")
        , actions.click 100 (Dom.id ("guild_openDm_" ++ dmUserId))
        ]


{-| Checks that the single polyline in the view is scaled by the given amount.
-}
expectPolylineScale : Float -> Test.Html.Query.Single msg -> Expect.Expectation
expectPolylineScale scale query =
    Test.Html.Query.find [ Test.Html.Selector.tag "polyline" ] query
        |> Test.Html.Query.has
            [ Test.Html.Selector.attribute
                (Svg.Attributes.transform ("scale(" ++ String.fromFloat scale ++ ")"))
            ]


expectPointsCloseTo : List ( Float, Float ) -> List ( Float, Float ) -> Result String ()
expectPointsCloseTo expected actual =
    if
        (List.length expected == List.length actual)
            && List.all
                identity
                (List.map2
                    (\( xA, yA ) ( xB, yB ) -> abs (xA - xB) < 0.001 && abs (yA - yB) < 0.001)
                    expected
                    actual
                )
    then
        Ok ()

    else
        Err ("Expected stroke points " ++ pointsToString expected ++ " but got " ++ pointsToString actual)


pointsToString : List ( Float, Float ) -> String
pointsToString list =
    List.map (\( x, y ) -> "(" ++ String.fromFloat x ++ "," ++ String.fromFloat y ++ ")") list
        |> String.join ", "


{-| The first channel of the most recently created guild.
-}
lastGuildChannel : BackendModel2 -> Maybe LocalState.BackendChannel
lastGuildChannel backend =
    case SeqDict.toList (unwrapBackend backend).guilds |> List.reverse |> List.head of
        Just ( _, guild ) ->
            SeqDict.get (Id.fromInt 0) guild.channels

        Nothing ->
            Nothing


{-| The most recent message in the first channel of the most recently created guild.
-}
lastGuildChannelMessage : BackendModel2 -> Maybe ( Id GuildId, Id ChannelMessageId, Message.Message ChannelMessageId (Id UserId) )
lastGuildChannelMessage backend =
    case SeqDict.toList (unwrapBackend backend).guilds |> List.reverse |> List.head of
        Just ( guildId, guild ) ->
            case SeqDict.get (Id.fromInt 0) guild.channels of
                Just channel ->
                    case IdArray.last channel.messages of
                        Just message ->
                            Just ( guildId, Id.fromInt (IdArray.length channel.messages - 1), message )

                        Nothing ->
                            Nothing

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


lastGuildChannelMessageAt : Id ChannelMessageId -> BackendModel2 -> Maybe (Message.Message ChannelMessageId (Id UserId))
lastGuildChannelMessageAt messageId backend =
    case lastGuildChannel backend of
        Just channel ->
            IdArray.get messageId channel.messages

        Nothing ->
            Nothing


{-| The first message with an image attached, in the first channel of the most recently created guild.
-}
findImageMessage : BackendModel2 -> Maybe ( Id ChannelMessageId, Id FileStatus.FileId )
findImageMessage backend =
    case lastGuildChannel backend of
        Just channel ->
            IdArray.toList channel.messages
                |> List.indexedMap Tuple.pair
                |> List.filterMap
                    (\( index, message ) ->
                        case message of
                            Message.UserTextMessage data ->
                                List.Nonempty.toList data.content
                                    |> List.filterMap
                                        (\part ->
                                            case part of
                                                RichText.AttachedFile fileId ->
                                                    Just ( Id.fromInt index, fileId )

                                                _ ->
                                                    Nothing
                                        )
                                    |> List.head

                            _ ->
                                Nothing
                    )
                |> List.head

        Nothing ->
            Nothing


{-| The first message with a loaded embed that contains an image, in the first
channel of the most recently created guild.
-}
findEmbedImageMessage : BackendModel2 -> Maybe (Id ChannelMessageId)
findEmbedImageMessage backend =
    case lastGuildChannel backend of
        Just channel ->
            IdArray.toList channel.messages
                |> List.indexedMap Tuple.pair
                |> List.filterMap
                    (\( index, message ) ->
                        case message of
                            Message.UserTextMessage data ->
                                case Array.get 0 data.embeds of
                                    Just (Embed.EmbedLoaded embed) ->
                                        case embed.image of
                                            Just _ ->
                                                Just (Id.fromInt index)

                                            Nothing ->
                                                Nothing

                                    _ ->
                                        Nothing

                            _ ->
                                Nothing
                    )
                |> List.head

        Nothing ->
            Nothing


{-| A click event on a drawing anchor. The clientX/Y and offsetX/Y fields are
used to determine the anchor element's screen position.
-}
drawingAnchorClick : Float -> Float -> Json.Encode.Value
drawingAnchorClick x y =
    Json.Encode.object
        [ ( "clientX", Json.Encode.float (x + 10) )
        , ( "clientY", Json.Encode.float (y + 5) )
        , ( "offsetX", Json.Encode.float 10 )
        , ( "offsetY", Json.Encode.float 5 )
        , -- The displayed size of the anchor element, used to center the zoom on the
          -- middle of the anchor. It has no effect on drawing while not zoomed in.
          ( "currentTarget", Json.Encode.object [ ( "offsetWidth", Json.Encode.float 40 ), ( "offsetHeight", Json.Encode.float 40 ) ] )
        ]


drawZigzagStroke :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
drawZigzagStroke client =
    T.group
        [ client.custom 100 Drawing.inputOverlayId "pointerdown" (drawingPointerEvent 50 30)
        , client.custom 30 Drawing.inputOverlayId "pointermove" (drawingPointerEvent 80 60)
        , client.custom 30 Drawing.inputOverlayId "pointermove" (drawingPointerEvent 110 30)
        , client.custom 30 Drawing.inputOverlayId "pointermove" (drawingPointerEvent 140 60)
        , client.custom 30 Drawing.inputOverlayId "pointermove" (drawingPointerEvent 170 30)
        , client.custom 30 Drawing.inputOverlayId "pointermove" (drawingPointerEvent 200 60)
        , client.custom 100 Drawing.inputOverlayId "pointerup" (Json.Encode.object [])
        ]


{-| A zigzag much wider than the embed container. With the anchor position
faked at (100, 100) by drawingAnchorClick, the stroke spans -60 to 520 on the
x axis relative to the embed image, which goes well past both edges of the
432px wide embed container.
-}
drawWideZigzagStroke :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
drawWideZigzagStroke client =
    T.group
        [ client.custom 100 Drawing.inputOverlayId "pointerdown" (drawingPointerEvent 40 130)
        , client.custom 30 Drawing.inputOverlayId "pointermove" (drawingPointerEvent 170 220)
        , client.custom 30 Drawing.inputOverlayId "pointermove" (drawingPointerEvent 300 130)
        , client.custom 30 Drawing.inputOverlayId "pointermove" (drawingPointerEvent 430 220)
        , client.custom 30 Drawing.inputOverlayId "pointermove" (drawingPointerEvent 560 130)
        , client.custom 30 Drawing.inputOverlayId "pointermove" (drawingPointerEvent 620 220)
        , client.custom 100 Drawing.inputOverlayId "pointerup" (Json.Encode.object [])
        ]


expectPolylineCount : Int -> Test.Html.Query.Single msg -> Expect.Expectation
expectPolylineCount count query =
    Test.Html.Query.findAll [ Test.Html.Selector.tag "polyline" ] query
        |> Test.Html.Query.count (Expect.equal count)


drawingPointerEvent : Float -> Float -> Json.Encode.Value
drawingPointerEvent x y =
    Json.Encode.object
        [ ( "button", Json.Encode.int 0 )
        , ( "isPrimary", Json.Encode.bool True )
        , ( "clientX", Json.Encode.float x )
        , ( "clientY", Json.Encode.float y )
        ]


{-| The end-to-end tests are parameterised over the backend model type, and `BackendModel`
is a 55 field record alias. Elm's canonical AST stores a record alias by writing the whole
record out at every occurrence (`TAlias` carries its expansion, and `TRecord` is
structural), while a custom type is stored as a name reference. That makes every test type
mentioning `BackendModel` enormous: `T.FrontendActions ... BackendModel` serialises to
8.6MB against 30KB with a custom type in that slot, and type checking has to carry those
structures for every expression in the test modules.

Wrapping the model in a custom type here gets the reference-sized version without touching
`Types.BackendModel` or the real app.

-}
type BackendModel2
    = BackendModel2 BackendModel


unwrapBackend : BackendModel2 -> BackendModel
unwrapBackend (BackendModel2 model) =
    model


{-| `Backend.app_` adapted to the wrapped model, for use in a test `T.Config`.
-}
backendApp : T.BackendApp ToBackend ToFrontend BackendMsg BackendModel2
backendApp =
    { init = Backend.app_.init |> Tuple.mapFirst BackendModel2
    , update =
        \msg model ->
            Backend.app_.update msg (unwrapBackend model) |> Tuple.mapFirst BackendModel2
    , updateFromFrontend =
        \sessionId clientId toBackend model ->
            Backend.app_.updateFromFrontend sessionId clientId toBackend (unwrapBackend model)
                |> Tuple.mapFirst BackendModel2
    , subscriptions =
        \model -> Backend.app_.subscriptions (unwrapBackend model)
    }
