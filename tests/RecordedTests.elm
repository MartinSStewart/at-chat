module RecordedTests exposing (main, setup)

import AiChat
import Array exposing (Array)
import Backend
import Broadcast
import Bytes exposing (Bytes)
import Codec
import Coord
import Dict exposing (Dict)
import Discord
import Duration
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Browser.Events exposing (Visibility(..))
import Effect.Lamdera as Lamdera exposing (SessionId)
import Effect.Test as T exposing (DelayInMs, FileUpload(..), HttpRequest, HttpResponse(..), MultipleFilesUpload(..), RequestedBy(..))
import Effect.Websocket as Websocket
import EmailAddress exposing (EmailAddress)
import Emoji
import Env
import Expect
import FileStatus
import Frontend
import Html.Attributes
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), DiscordGuildOrDmId_DmData, GuildId, GuildOrDmId(..), Id, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId)
import ImageEditor
import Json.Decode
import Json.Encode
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import Local exposing (ChangeId(..))
import LoginForm
import NonemptyDict
import Pages.Admin
import Pages.Guild
import Pages.Home
import Parser exposing ((|.), (|=))
import PersonName
import RichText exposing (Domain(..), RichText(..))
import Route
import SafeJson exposing (SafeJson(..))
import SecretId exposing (SecretId(..))
import SeqDict
import SessionIdHash exposing (SessionIdHash(..))
import Slack
import Test.Html.Query
import Test.Html.Selector
import TextEditor
import Time
import TwoFactorAuthentication
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, InitialLoadRequest(..), LocalChange(..), LoginTokenData(..), ToBackend(..), ToFrontend(..))
import Unsafe
import Url exposing (Url)
import User
import UserAgent
import UserSession exposing (NotificationMode(..), SetViewing(..), ToBeFilledInByBackend(..))
import VisibleMessages


setup : T.ViewerWith (List (T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel))
setup =
    T.viewerWith tests
        |> T.addBytesFiles (Dict.values fileRequests)
        |> T.addStringFile "/tests/data/discord-op0-ready.json"
        |> T.addStringFile "/tests/data/discord-op0-ready-supplemental.json"
        |> T.addBytesFile "/tests/data/at-user-icon.png"
        |> T.addStringFile "/public/compact-emoji.json"


main : Program () (T.Model ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel) (T.Msg ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
main =
    T.startViewer setup


domain : Url
domain =
    { protocol = Url.Http, host = "localhost", port_ = Just 8000, path = "", query = Nothing, fragment = Nothing }


{-| Please don't modify or rename this function
-}
fileRequests : Dict String String
fileRequests =
    [ ( "GET_http://localhost:3000/file/vapid", "/tests/data/1b846b6a39f0b828.txt" )
    , ( "POST_https://api.postmarkapp.com/email", "/tests/data/2911db1dd6723eb4.txt" )
    , ( "GET_/compact-emoji.json", "/public/compact-emoji.json" )
    ]
        |> Dict.fromList


stringToJson : String -> Json.Encode.Value
stringToJson json =
    Result.withDefault Json.Encode.null (Json.Decode.decodeString Json.Decode.value json)


handlePortToJs :
    { currentRequest : T.PortToJs, data : T.Data FrontendModel BackendModel }
    -> Maybe ( String, Json.Decode.Value )
handlePortToJs requestAndData =
    case requestAndData.currentRequest.portName of
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

        "register_push_subscription_to_js" ->
            ( "register_push_subscription_from_js"
            , Json.Encode.object
                [ ( "endpoint", Json.Encode.string "https://vapidserver.com/" )
                , ( "keys"
                  , Json.Encode.object
                        [ ( "auth", Json.Encode.string "123" )
                        , ( "p256dh", Json.Encode.string "abc" )
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


isLogErrorEmail : String -> HttpRequest -> Maybe String
isLogErrorEmail emailAddress httpRequest =
    if httpRequest.url == "https://api.postmarkapp.com/email" then
        case httpRequest.body of
            T.JsonBody value ->
                case Json.Decode.decodeValue decodePostmark value of
                    Ok ( subject, to, body ) ->
                        case ( emailAddress == EmailAddress.toString to, subject, String.split ":" body ) of
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
    Unsafe.emailAddress Env.adminEmail


userEmail : EmailAddress
userEmail =
    Unsafe.emailAddress "user@mail.com"


joeEmail : EmailAddress
joeEmail =
    Unsafe.emailAddress "joe@hotmail.com"


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
                                            && (request.url == "http://localhost:3000/file/push-notification")

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
                                            && (request.url == "http://localhost:3000/file/push-notification")

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
    (T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
     -> T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
     -> List (T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
    )
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
connectTwoUsersAndJoinNewGuild continueFunc =
    T.connectFrontend
        100
        sessionId0
        "/"
        desktopWindow
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
                                desktopWindow
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


writeMessage : T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel -> String -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
writeMessage user text =
    T.group
        [ user.focus 200 (Dom.id "channel_textinput")
        , user.click 1005 (Dom.id "channel_textinput")
        , user.input 100 (Dom.id "channel_textinput") text
        , user.keyDown 100 (Dom.id "channel_textinput") "Enter" []
        , user.blur 100 (Dom.id "channel_textinput")
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


handleHttpRequests : Dict String String -> Dict String Bytes -> { currentRequest : HttpRequest, data : T.Data FrontendModel BackendModel } -> HttpResponse
handleHttpRequests overrides fileData requestAndData =
    let
        key : String
        key =
            requestAndData.currentRequest.method
                ++ "_"
                ++ requestAndData.currentRequest.url
                |> Debug.log "key"

        getData : String -> HttpResponse
        getData path =
            case Dict.get path fileData of
                Just data ->
                    BytesHttpResponse { url = requestAndData.currentRequest.url, statusCode = 200, statusText = "OK", headers = Dict.empty } data

                Nothing ->
                    UnhandledHttpRequest
    in
    if key == "GET_/_i" then
        StringHttpResponse
            { url = requestAndData.currentRequest.url, statusCode = 200, statusText = "OK", headers = Dict.empty }
            infoEndpointResponse

    else
        case ( Dict.get key overrides, Dict.get key fileRequests ) of
            ( Just path, _ ) ->
                getData path

            ( Nothing, Just path ) ->
                getData path

            _ ->
                UnhandledHttpRequest


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


discordUserAuth : Discord.UserAuth
discordUserAuth =
    { token = "fake-token"
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


infoEndpointResponse : String
infoEndpointResponse =
    """{"s":"unknown","v":136,"h":["ce04ec5a052111b470b778b6adec9470dd0ab1d2","881990760d6345c8ebcecb11eeb3d7c3caa48d52","5bf58bad725a2b57b8b04c61329291b3ddc57f89","121b2b6733a1d45f0aa03a86227cb260fa0aca63","dc23f82c404f7f9881562c94f59dddf1f291d0b5","a7f4d07c436ed96853c669d38f8591f0d64d57cd"],"o":"a12","p":15}"""


handleCustomRequest : String -> String -> HttpResponse
handleCustomRequest method url =
    if String.startsWith "https://" url then
        case ( method, String.dropLeft 8 url |> String.split "/" ) of
            ( "GET", [ "discord.com", "api", "v9", "users", "@me" ] ) ->
                StringHttpResponse
                    { url = url, statusCode = 200, statusText = "OK", headers = Dict.empty }
                    """{"id":"184437096813953035","username":"at28727","avatar":"7c40cb63ea11096169c5a4dcb5825a3d","discriminator":"0","public_flags":0,"flags":0,"banner":null,"accent_color":null,"global_name":"AT2","avatar_decoration_data":null,"collectibles":null,"display_name_styles":null,"banner_color":null,"clan":null,"primary_guild":null,"mfa_enabled":false,"locale":"en-US","premium_type":0,"email":"a@a.se","verified":true,"phone":null,"nsfw_allowed":null,"linked_users":[],"bio":"","authenticator_types":[],"age_verification_status":1}"""

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


decodeCustomRequest : HttpRequest -> Maybe ( String, String )
decodeCustomRequest request =
    case request.body of
        T.JsonBody json ->
            Json.Decode.decodeValue
                (Json.Decode.map2
                    Tuple.pair
                    (Json.Decode.field "method" Json.Decode.string)
                    (Json.Decode.field "url" Json.Decode.string)
                )
                json
                |> Result.toMaybe

        _ ->
            Nothing


tests : Dict String Bytes -> String -> String -> Bytes -> String -> List (T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
tests fileData discordOp0Ready discordOp0ReadySupplemental atUserIcon emojiJson =
    let
        handleNormalHttpRequests : ({ currentRequest : HttpRequest, data : T.Data FrontendModel BackendModel } -> Maybe HttpResponse) -> { currentRequest : HttpRequest, data : T.Data FrontendModel BackendModel } -> HttpResponse
        handleNormalHttpRequests overrides ({ currentRequest } as httpRequests) =
            case overrides httpRequests of
                Just response ->
                    response

                Nothing ->
                    case currentRequest.url of
                        "/_i" ->
                            StringHttpResponse
                                { url = currentRequest.url
                                , statusCode = 200
                                , statusText = "OK"
                                , headers = Dict.empty
                                }
                                infoEndpointResponse

                        "/compact-emoji.json" ->
                            StringHttpResponse
                                { url = currentRequest.url
                                , statusCode = 200
                                , statusText = "OK"
                                , headers = Dict.empty
                                }
                                emojiJson

                        "http://localhost:3000/file/custom-request" ->
                            case decodeCustomRequest currentRequest of
                                Just ( method, url ) ->
                                    handleCustomRequest method url

                                Nothing ->
                                    let
                                        _ =
                                            Debug.log "Failed to decode custom request" ()
                                    in
                                    UnhandledHttpRequest

                        "http://localhost:3000/file/vapid" ->
                            StringHttpResponse
                                { url = currentRequest.url
                                , statusCode = 200
                                , statusText = "OK"
                                , headers = Dict.empty
                                }
                                "BIMi0iQoEXBXE3DyvGBToZfTfC8OyTn5lr_8eMvGBzJbxdEzv4wXFwIOEna_X3NJnCqIMbZX81VgSOFCjYda0bo,Ik2bRdqy_1dPMyiHxJX3_mV_t5R0GpQjsIu71E4MkCU"

                        "http://localhost:3000/file/upload" ->
                            StringHttpResponse
                                { url = currentRequest.url
                                , statusCode = 200
                                , statusText = "OK"
                                , headers = Dict.empty
                                }
                                (Codec.encodeToString
                                    0
                                    FileStatus.uploadResponseCodec
                                    { fileHash = FileStatus.fileHash "123123123"
                                    , imageSize =
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

                        "http://localhost:3000/file/push-notification" ->
                            StringHttpResponse
                                { url = currentRequest.url
                                , statusCode = 200
                                , statusText = "OK"
                                , headers = Dict.empty
                                }
                                ""

                        "http://localhost:3000/file/embed" ->
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

                        "https://api.postmarkapp.com/email" ->
                            case currentRequest.body of
                                T.JsonBody json ->
                                    case Json.Decode.decodeValue (Json.Decode.field "To" Json.Decode.string) json of
                                        Ok email ->
                                            StringHttpResponse
                                                { url = currentRequest.url
                                                , statusCode = 200
                                                , statusText = "OK"
                                                , headers = Dict.empty
                                                }
                                                ("""{"To":\""""
                                                    ++ email
                                                    ++ """","SubmittedAt":"2023-09-30T14:26:56.6614723Z","MessageID":"edd386b7-63f1-471f-a4ba-2b216188fb6c","ErrorCode":0,"Message":"OK"}"""
                                                )

                                        Err err ->
                                            let
                                                _ =
                                                    Debug.log "Parse postmark request error" err
                                            in
                                            UnhandledHttpRequest

                                _ ->
                                    UnhandledHttpRequest

                        _ ->
                            if String.startsWith "https://cdn.discordapp.com/avatars/" currentRequest.url then
                                BytesHttpResponse
                                    { url = currentRequest.url
                                    , statusCode = 200
                                    , statusText = "OK"
                                    , headers = Dict.empty
                                    }
                                    atUserIcon

                            else
                                UnhandledHttpRequest

        handleFileRequest : { data : T.Data frontendModel backendModel, mimeTypes : List String } -> FileUpload
        handleFileRequest _ =
            UnhandledFileUpload

        handleMultiFileUpload : { data : T.Data frontendModel backendModel, mimeTypes : List String } -> MultipleFilesUpload
        handleMultiFileUpload _ =
            UnhandledMultiFileUpload

        normalConfig : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
        normalConfig =
            T.Config
                Frontend.app_
                Backend.app_
                (handleNormalHttpRequests (\_ -> Nothing))
                handlePortToJs
                handleFileRequest
                handleMultiFileUpload
                domain

        config =
            T.Config
                Frontend.app_
                Backend.app_
                (handleHttpRequests
                    Dict.empty
                    fileData
                )
                (\_ -> Nothing)
                (\_ -> UnhandledFileUpload)
                (\_ -> UnhandledMultiFileUpload)
                domain
    in
    [ attackerTriesToLeakSensitiveData normalConfig
    , inviteUserAndDmChat config
    , T.start
        "Admin can open admin page"
        startTime
        config
        [ T.connectFrontend
            100
            sessionId0
            "/"
            desktopWindow
            (\admin ->
                [ handleLogin firefoxDesktop adminEmail admin
                , admin.click 100 (Dom.id "guild_showUserOptions")
                , admin.click 100 (Dom.id "userOptions_gotoAdmin")
                , admin.click 100 (Dom.id "admin_goToHomepage")
                ]
            )
        ]
    , T.start
        "Create message with embeds and then edit that message"
        startTime
        normalConfig
        [ connectTwoUsersAndJoinNewGuild
            (\admin user ->
                let
                    checkCards : Int -> Int -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
                    checkCards elmCampCardCount meetdownCardCount =
                        [ admin.checkView
                            100
                            (\html ->
                                Test.Html.Query.findAll [ Test.Html.Selector.exactText "Title for https://elm.camp/" ] html
                                    |> Test.Html.Query.count (Expect.equal elmCampCardCount)
                            )
                        , admin.checkView
                            100
                            (\html ->
                                Test.Html.Query.findAll [ Test.Html.Selector.exactText "Title for https://meetdown.app/" ] html
                                    |> Test.Html.Query.count (Expect.equal meetdownCardCount)
                            )
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Title for https://some-other-website.app/" ])
                        , user.checkView
                            100
                            (\html ->
                                Test.Html.Query.findAll [ Test.Html.Selector.exactText "Title for https://elm.camp/" ] html
                                    |> Test.Html.Query.count (Expect.equal elmCampCardCount)
                            )
                        , user.checkView
                            100
                            (\html ->
                                Test.Html.Query.findAll [ Test.Html.Selector.exactText "Title for https://meetdown.app/" ] html
                                    |> Test.Html.Query.count (Expect.equal meetdownCardCount)
                            )
                        , user.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Title for https://some-other-website.app/" ])
                        ]
                            |> T.collapsableGroup "Check cards"
                in
                [ writeMessage admin "Test https://elm.camp/ https://elm.camp/ https://meetdown.app/"
                , checkCards 2 1
                , T.collapsableGroup
                    "Edit message"
                    [ admin.custom
                        100
                        (Dom.id "guild_message_1")
                        "contextmenu"
                        (Json.Encode.object
                            [ ( "clientX", Json.Encode.float 50 )
                            , ( "clientY", Json.Encode.float 150 )
                            ]
                        )
                    , user.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.text "(editing...)" ])
                    , admin.click 2000 (Dom.id "messageMenu_editMessage")
                    , admin.input 200 (Dom.id "editMessageTextInput") "Edited https://elm.camp/ https://some-other-website.app/"
                    , user.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.text "(editing...)" ])
                    , admin.keyDown 100 (Dom.id "editMessageTextInput") "Enter" []
                    ]
                , checkCards 1 0
                ]
            )
        ]
    , T.testGroup "Discord"
        [ T.start
            "Link Discord account with login"
            startTime
            normalConfig
            [ linkDiscordAndLogin
                sessionId0
                (PersonName.toString Backend.adminUser.name)
                adminEmail
                False
                discordOp0Ready
                discordOp0ReadySupplemental
                (\_ -> [])
            ]
        , T.start
            "Link Discord account with login to non-existent at-chat account"
            startTime
            normalConfig
            [ linkDiscordAndLogin
                sessionId0
                "Steve"
                userEmail
                True
                discordOp0Ready
                discordOp0ReadySupplemental
                (\user ->
                    [ user.click 100 (Dom.id "guild_showUserOptions")
                    , user.checkView
                        100
                        (Test.Html.Query.has
                            [ Test.Html.Selector.exactText "at0232"
                            , Test.Html.Selector.exactText "a@a.se"
                            ]
                        )
                    ]
                )
            ]
        , T.start
            "Link Discord account already logged in"
            startTime
            normalConfig
            [ T.connectFrontend
                100
                sessionId0
                "/"
                desktopWindow
                (\adminA ->
                    [ handleLogin firefoxDesktop adminEmail adminA
                    , adminA.click 100 (Dom.id "guild_showUserOptions")
                    , adminA.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Loading user data" ])
                    , T.connectFrontend
                        100
                        sessionId0
                        ("/link-discord/?data=" ++ Codec.encodeToString 0 User.linkDiscordDataCodec discordUserAuth)
                        desktopWindow
                        (\adminB ->
                            [ adminB.portEvent 10 "user_agent_from_js" (Json.Encode.string firefoxDesktop)
                            , adminA.checkView
                                200
                                (Test.Html.Query.has [ Test.Html.Selector.exactText "Loading user data" ])
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
                            , adminB.checkView
                                100
                                (Test.Html.Query.has
                                    [ Test.Html.Selector.exactText (PersonName.toString Backend.adminUser.name)
                                    , Test.Html.Selector.exactText "at0232"
                                    , Test.Html.Selector.exactText "kess"
                                    , Test.Html.Selector.exactText "purplelite"
                                    ]
                                )
                            ]
                        )
                    ]
                )
            ]
        , T.start
            "Ping discord user"
            startTime
            normalConfig
            [ linkDiscordAndLogin
                sessionId0
                (PersonName.toString Backend.adminUser.name)
                adminEmail
                False
                discordOp0Ready
                discordOp0ReadySupplemental
                (\user ->
                    [ user.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                    , user.input 100 Pages.Guild.channelTextInputId "Hello @purplelite!"
                    , user.keyDown 100 Pages.Guild.channelTextInputId "Enter" []
                    , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "@purplelite" ])
                    ]
                )
            ]
        , T.start
            "Unlinked Discord user starts thread from message"
            startTime
            normalConfig
            [ linkDiscordAndLogin
                sessionId0
                (PersonName.toString Backend.adminUser.name)
                adminEmail
                False
                discordOp0Ready
                discordOp0ReadySupplemental
                (\user ->
                    [ user.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                    , andThenWebsocket
                        (\connection _ ->
                            [ T.websocketSendString
                                100
                                connection
                                "{\"t\":\"MESSAGE_CREATE\",\"s\":4,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-03-26T10:56:15.024000+00:00\",\"pinned\":false,\"nonce\":\"1486680174970798080\",\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"705745250815311942\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Thread start message\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                            , T.websocketSendString
                                100
                                connection
                                "{\"t\":\"MESSAGE_UPDATE\",\"s\":5,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-03-26T10:56:15.024000+00:00\",\"pinned\":false,\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"705745250815311942\",\"flags\":32,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Thread start message\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                            , T.websocketSendString
                                100
                                connection
                                "{\"t\":\"GUILD_AUDIT_LOG_ENTRY_CREATE\",\"s\":6,\"op\":0,\"d\":{\"user_id\":\"161098476632014848\",\"target_id\":\"705745250815311942\",\"id\":\"1486680242226598131\",\"changes\":[{\"new_value\":\"Custom thread name\",\"key\":\"name\"},{\"new_value\":11,\"key\":\"type\"},{\"new_value\":false,\"key\":\"archived\"},{\"new_value\":false,\"key\":\"locked\"},{\"new_value\":4320,\"key\":\"auto_archive_duration\"},{\"new_value\":0,\"key\":\"rate_limit_per_user\"},{\"new_value\":0,\"key\":\"flags\"}],\"action_type\":110,\"guild_id\":\"705745250815311942\"}}"
                            , T.websocketSendString
                                100
                                connection
                                "{\"t\":\"THREAD_MEMBERS_UPDATE\",\"s\":7,\"op\":0,\"d\":{\"member_ids_preview\":[\"161098476632014848\",\"184437096813953035\"],\"member_count\":2,\"id\":\"705745250815311942\",\"added_members\":[{\"user_id\":\"184437096813953035\",\"presence\":{\"user\":{\"username\":\"at28727\",\"primary_guild\":null,\"id\":\"184437096813953035\",\"global_name\":\"AT2\",\"discriminator\":\"0\",\"clan\":null,\"bot\":false,\"avatar_decoration_data\":null,\"avatar\":\"7c40cb63ea11096169c5a4dcb5825a3d\"},\"status\":\"online\",\"processed_at_timestamp\":0,\"game\":null,\"client_status\":{\"web\":\"online\"},\"activities\":[]},\"muted\":false,\"mute_config\":null,\"member\":{\"user\":{\"username\":\"at28727\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"184437096813953035\",\"global_name\":\"AT2\",\"display_name_styles\":null,\"display_name\":\"AT2\",\"discriminator\":\"0\",\"collectibles\":null,\"bot\":false,\"avatar_decoration_data\":null,\"avatar\":\"7c40cb63ea11096169c5a4dcb5825a3d\"},\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2025-10-11T19:44:51.312000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"join_timestamp\":\"2026-03-26T10:56:31.471913+00:00\",\"id\":\"705745250815311942\",\"flags\":1}],\"guild_id\":\"705745250815311942\"}}"
                            , T.websocketSendString
                                100
                                connection
                                "{\"t\":\"THREAD_CREATE\",\"s\":8,\"op\":0,\"d\":{\"type\":11,\"total_message_sent\":0,\"thread_metadata\":{\"locked\":false,\"create_timestamp\":\"2026-03-26T10:56:30.898915+00:00\",\"auto_archive_duration\":4320,\"archived\":false,\"archive_timestamp\":\"2026-03-26T10:56:30.898915+00:00\"},\"rate_limit_per_user\":0,\"parent_id\":\"1072828564317159465\",\"owner_id\":\"161098476632014848\",\"name\":\"Custom thread name\",\"message_count\":0,\"member_ids_preview\":[\"161098476632014848\",\"184437096813953035\"],\"member_count\":2,\"member\":{\"user_id\":\"184437096813953035\",\"muted\":false,\"mute_config\":null,\"join_timestamp\":\"2026-03-26T10:56:31.471913+00:00\",\"id\":\"705745250815311942\",\"flags\":1},\"last_message_id\":\"1486680242226598130\",\"id\":\"705745250815311942\",\"guild_id\":\"705745250815311942\",\"flags\":0}}"
                            , T.andThen
                                100
                                (\data ->
                                    case
                                        List.filter
                                            (\request ->
                                                case ( request.url, decodeCustomRequest request ) of
                                                    ( "http://localhost:3000/file/custom-request", Just ( method, url ) ) ->
                                                        (url == "https://discord.com/api/v9/channels/705745250815311942/thread-members/@me")
                                                            && (method == "PUT")

                                                    _ ->
                                                        False
                                            )
                                            data.httpRequests
                                    of
                                        [ _ ] ->
                                            [ T.websocketSendString
                                                100
                                                connection
                                                "{\"t\":\"MESSAGE_CREATE\",\"s\":9,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-03-26T10:56:31.678000+00:00\",\"position\":0,\"pinned\":false,\"nonce\":\"1486680244629798912\",\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1486680245363802275\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"First message inside thread\",\"components\":[],\"channel_type\":11,\"channel_id\":\"705745250815311942\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                                            , user.checkView
                                                100
                                                (Test.Html.Query.has
                                                    [ Test.Html.Selector.exactText "Thread start message"
                                                    , Test.Html.Selector.exactText "First message inside thread"
                                                    ]
                                                )
                                            ]

                                        _ ->
                                            [ T.checkBackend 100 (\_ -> Err "Didn't join thread") ]
                                )
                            ]
                        )
                    ]
                )
            ]
        , T.start
            "Unlinked Discord user starts stand-alone thread"
            startTime
            normalConfig
            [ linkDiscordAndLogin
                sessionId0
                (PersonName.toString Backend.adminUser.name)
                adminEmail
                False
                discordOp0Ready
                discordOp0ReadySupplemental
                (\user ->
                    [ user.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                    , andThenWebsocket
                        (\connection _ ->
                            [ T.websocketSendString
                                100
                                connection
                                "{\"t\":\"MESSAGE_CREATE\",\"s\":4,\"op\":0,\"d\":{\"type\":18,\"tts\":false,\"timestamp\":\"2026-03-26T12:10:08.752000+00:00\",\"pinned\":false,\"message_reference\":{\"type\":0,\"guild_id\":\"705745250815311942\",\"channel_id\":\"1486698771915083887\"},\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1486698771915083887\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Thread title\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                            , T.websocketSendString
                                100
                                connection
                                "{\"t\":\"MESSAGE_UPDATE\",\"s\":5,\"op\":0,\"d\":{\"type\":18,\"tts\":false,\"timestamp\":\"2026-03-26T12:10:08.752000+00:00\",\"pinned\":false,\"message_reference\":{\"type\":0,\"guild_id\":\"705745250815311942\",\"channel_id\":\"1486698771915083887\"},\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1486698771915083887\",\"flags\":32,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Thread title\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                            , T.websocketSendString
                                100
                                connection
                                "{\"t\":\"GUILD_AUDIT_LOG_ENTRY_CREATE\",\"s\":6,\"op\":0,\"d\":{\"user_id\":\"161098476632014848\",\"target_id\":\"1486698771915083887\",\"id\":\"1486698771915083888\",\"changes\":[{\"new_value\":\"Thread title\",\"key\":\"name\"},{\"new_value\":11,\"key\":\"type\"},{\"new_value\":false,\"key\":\"archived\"},{\"new_value\":false,\"key\":\"locked\"},{\"new_value\":4320,\"key\":\"auto_archive_duration\"},{\"new_value\":0,\"key\":\"rate_limit_per_user\"},{\"new_value\":0,\"key\":\"flags\"}],\"action_type\":110,\"guild_id\":\"705745250815311942\"}}"
                            , T.websocketSendString
                                100
                                connection
                                "{\"t\":\"THREAD_MEMBERS_UPDATE\",\"s\":7,\"op\":0,\"d\":{\"member_ids_preview\":[\"161098476632014848\",\"184437096813953035\"],\"member_count\":2,\"id\":\"1486698771915083887\",\"added_members\":[{\"user_id\":\"184437096813953035\",\"presence\":{\"user\":{\"username\":\"at28727\",\"primary_guild\":null,\"id\":\"184437096813953035\",\"global_name\":\"AT2\",\"discriminator\":\"0\",\"clan\":null,\"bot\":false,\"avatar_decoration_data\":null,\"avatar\":\"7c40cb63ea11096169c5a4dcb5825a3d\"},\"status\":\"online\",\"processed_at_timestamp\":0,\"game\":null,\"client_status\":{\"web\":\"online\"},\"activities\":[]},\"muted\":false,\"mute_config\":null,\"member\":{\"user\":{\"username\":\"at28727\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"184437096813953035\",\"global_name\":\"AT2\",\"display_name_styles\":null,\"display_name\":\"AT2\",\"discriminator\":\"0\",\"collectibles\":null,\"bot\":false,\"avatar_decoration_data\":null,\"avatar\":\"7c40cb63ea11096169c5a4dcb5825a3d\"},\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2025-10-11T19:44:51.312000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"join_timestamp\":\"2026-03-26T12:10:09.250111+00:00\",\"id\":\"1486698771915083887\",\"flags\":1}],\"guild_id\":\"705745250815311942\"}}"
                            , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Thread title" ])
                            , T.andThen
                                100
                                (\data ->
                                    case
                                        List.filter
                                            (\request ->
                                                case ( request.url, decodeCustomRequest request ) of
                                                    ( "http://localhost:3000/file/custom-request", Just ( method, url ) ) ->
                                                        (Debug.log "url" url == "https://discord.com/api/v9/channels/1486698771915083887/thread-members/@me")
                                                            && (method == "PUT")

                                                    _ ->
                                                        False
                                            )
                                            (Debug.log "request" data.httpRequests)
                                    of
                                        [ _ ] ->
                                            [ T.websocketSendString
                                                100
                                                connection
                                                "{\"t\":\"THREAD_CREATE\",\"s\":8,\"op\":0,\"d\":{\"type\":11,\"total_message_sent\":0,\"thread_metadata\":{\"locked\":false,\"create_timestamp\":\"2026-03-26T12:10:08.752000+00:00\",\"auto_archive_duration\":4320,\"archived\":false,\"archive_timestamp\":\"2026-03-26T12:10:08.752000+00:00\"},\"rate_limit_per_user\":0,\"parent_id\":\"1072828564317159465\",\"owner_id\":\"161098476632014848\",\"name\":\"Thread title\",\"message_count\":0,\"member_ids_preview\":[\"161098476632014848\",\"184437096813953035\"],\"member_count\":2,\"member\":{\"user_id\":\"184437096813953035\",\"muted\":false,\"mute_config\":null,\"join_timestamp\":\"2026-03-26T12:10:09.250111+00:00\",\"id\":\"1486698771915083887\",\"flags\":1},\"last_message_id\":null,\"id\":\"1486698771915083887\",\"guild_id\":\"705745250815311942\",\"flags\":0}}"
                                            , T.websocketSendString
                                                100
                                                connection
                                                "{\"t\":\"MESSAGE_CREATE\",\"s\":9,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-03-26T12:10:09.497000+00:00\",\"position\":0,\"pinned\":false,\"nonce\":\"1486698774058237952\",\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1486698775039967375\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Thread message\",\"components\":[],\"channel_type\":11,\"channel_id\":\"1486698771915083887\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                                            , user.checkView
                                                100
                                                (Test.Html.Query.has
                                                    [ Test.Html.Selector.exactText "Thread title"
                                                    , Test.Html.Selector.exactText "Thread message"
                                                    ]
                                                )
                                            ]

                                        _ ->
                                            [ T.checkBackend 100 (\_ -> Err "Didn't join thread") ]
                                )
                            ]
                        )
                    ]
                )
            ]
        ]
    , T.start
        "Connect multiple devices"
        startTime
        normalConfig
        [ T.connectFrontend
            100
            sessionId0
            "/"
            desktopWindow
            (\adminA ->
                [ handleLogin firefoxDesktop adminEmail adminA
                , adminA.click 100 (Dom.id "guild_showUserOptions")
                , hasExactText adminA [ "Desktop • Firefox (current device)" ]
                , T.connectFrontend
                    100
                    sessionId1
                    "/"
                    desktopWindow
                    (\adminB ->
                        [ handleLogin safariIphone adminEmail adminB
                        , hasExactText adminA [ "Mobile • Safari", "Desktop • Firefox (current device)" ]
                        , adminB.click 100 (Dom.id "guild_showUserOptions")
                        , T.connectFrontend
                            100
                            sessionId2
                            "/"
                            desktopWindow
                            (\adminC ->
                                [ handleLogin chromeDesktop adminEmail adminC
                                , hasExactText
                                    adminA
                                    [ "Mobile • Safari"
                                    , "Desktop • Firefox (current device)"
                                    , "Desktop • Chrome"
                                    ]
                                , adminC.click 100 (Dom.id "guild_showUserOptions")
                                , hasExactText
                                    adminC
                                    [ "Mobile • Safari"
                                    , "Desktop • Firefox"
                                    , "Desktop • Chrome (current device)"
                                    ]
                                ]
                            )
                        , adminB.click 100 (Dom.id "options_logout")
                        , hasNotExactText adminA [ "Mobile • Safari" ]
                        , hasExactText adminA [ "Desktop • Chrome", "Desktop • Firefox (current device)" ]
                        ]
                    )
                ]
            )
        ]
    , T.start
        "spoilers"
        startTime
        normalConfig
        [ connectTwoUsersAndJoinNewGuild
            (\admin user ->
                [ writeMessage admin "This message is ||very|| ||secret||"
                , admin.mouseEnter 100 (Dom.id "guild_message_1") ( 10, 10 ) []
                , admin.custom
                    100
                    (Dom.id "miniView_reply")
                    "click"
                    (Json.Encode.object
                        [ ( "clientX", Json.Encode.int 300 )
                        , ( "clientY", Json.Encode.int 300 )
                        ]
                    )
                , writeMessage admin "Another ||*super*|| *||secret||* message"
                , clickSpoiler user (Dom.id "spoiler_1_0")
                , clickSpoiler user (Dom.id "spoiler_1_1")
                , clickSpoiler user (Dom.id "spoiler_2_1")
                , clickSpoiler user (Dom.id "spoiler_2_0")
                , createThread admin (Id.fromInt 2)
                , clickSpoiler admin (Dom.id "spoiler_2_0")
                , clickSpoiler admin (Dom.id "spoiler_2_1")
                , writeMessage admin "||*super*|| ||duper|| *||secret||* text"
                , user.click 100 (Dom.id "guild_threadStarterIndicator_2")
                , clickSpoiler admin (Dom.id "threadSpoiler_0_0")
                , clickSpoiler admin (Dom.id "threadSpoiler_0_2")
                ]
            )
        ]
    , T.start
        "Mobile edit message"
        startTime
        normalConfig
        [ T.connectFrontend
            100
            sessionId2
            "/"
            mobileWindow
            (\admin ->
                [ handleLogin safariIphone adminEmail admin
                , admin.click 100 (Dom.id "guild_openGuild_0")
                , writeMessageMobile admin "Test"
                , admin.custom
                    100
                    (Dom.id "guild_message_0")
                    "contextmenu"
                    (Json.Encode.object
                        [ ( "clientX", Json.Encode.float 50 )
                        , ( "clientY", Json.Encode.float 150 )
                        ]
                    )
                , admin.click 2000 (Dom.id "messageMenu_editMessage")
                , admin.input 1000 (Dom.id "editMessageTextInput") "Test Edited"
                , admin.input 200 (Dom.id "editMessageTextInput") "Test Edited\nLinebreak"
                , admin.click 1000 (Dom.id "messageMenu_editMobile_sendMessage")
                ]
            )
        ]
    , T.start
        "Desktop edit message"
        startTime
        normalConfig
        [ T.connectFrontend
            100
            sessionId2
            "/"
            desktopWindow
            (\admin ->
                [ handleLogin safariIphone adminEmail admin
                , admin.click 100 (Dom.id "guild_openGuild_0")
                , writeMessageMobile admin "Test"
                , admin.custom
                    100
                    (Dom.id "guild_message_0")
                    "contextmenu"
                    (Json.Encode.object
                        [ ( "clientX", Json.Encode.float 50 )
                        , ( "clientY", Json.Encode.float 150 )
                        ]
                    )
                , hasExactText admin [ "Edit message" ]
                , admin.click 2000 (Dom.id "messageMenu_editMessage")
                , hasNotExactText admin [ "Edit message" ]
                , admin.input 1000 (Dom.id "editMessageTextInput") "Test Edited"
                , admin.input 200 (Dom.id "editMessageTextInput") "Test Edited\nLinebreak"
                , hasText admin [ "to cancel edit" ]
                , admin.keyDown 100 (Dom.id "editMessageTextInput") "Enter" []
                , hasNotText admin [ "to cancel edit" ]
                ]
            )
        ]
    , T.start
        "Change notification level"
        startTime
        normalConfig
        [ connectTwoUsersAndJoinNewGuild
            (\admin user ->
                [ user.click 100 (Dom.id "guild_inviteLinkCreatorRoute")
                , user.keyUp 100 (Dom.id "guild_notificationLevel") "ArrowDown" []
                , writeMessage admin "Test"
                , checkNotification "Test"
                , writeMessage admin "Test 2"
                , user.click 100 (Dom.id "guild_openChannel_0")
                , writeMessage user "I shouldn't get notified"
                , checkNoNotification "I shouldn't get notified"
                ]
            )
        ]

    --, T.start
    --    "Remove direct mention when viewed on another session"
    --    startTime
    --    normalConfig
    --    [ connectTwoUsersAndJoinNewGuild
    --        (\admin user ->
    --            [ user.click 100 (Dom.id "guildIcon_showFriends")
    --            , writeMessage admin "@Stevie Steve"
    --            , writeMessage admin "@Stevie Steve"
    --            , writeMessage admin "@Stevie Steve"
    --            , hasExactText user [ "3" ]
    --            , T.connectFrontend
    --                100
    --                sessionId1
    --                (Route.encode Route.HomePageRoute)
    --                desktopWindow
    --                (\userReload ->
    --                    [ userReload.portEvent 10 "user_agent_from_js" (Json.Encode.string firefoxDesktop)
    --                    , userReload.click 100 (Dom.id "guild_openGuild_1")
    --                    , hasExactText user [ "3" ]
    --                    , userReload.click 100 (Dom.id "guildIcon_showFriends")
    --                    , hasNotExactText user [ "3" ]
    --                    ]
    --                )
    --            ]
    --        )
    --    ]
    , T.start
        "Check notification icons appear"
        startTime
        normalConfig
        [ connectTwoUsersAndJoinNewGuild
            (\admin user ->
                [ user.click 100 (Dom.id "guildIcon_showFriends")
                , admin.click 100 (Dom.id "guild_newChannel")
                , admin.input 100 (Dom.id "newChannelName") "Second-channel-goes-here"
                , admin.click 100 (Dom.id "guild_createChannel")
                , writeMessage admin "First message"
                , writeMessage admin "Next message"
                , writeMessage admin "Third message"
                , hasExactText user [ "3" ]
                , user.click 100 (Dom.id "guild_openGuild_1")
                , hasExactText user [ "3" ]
                , writeMessage admin "@Stevie Steve Hello!"
                , writeMessage admin "@Stevie Steve Hello again!"
                , hasExactText user [ "2" ]
                , T.connectFrontend
                    100
                    sessionId1
                    (Route.encode Route.HomePageRoute)
                    desktopWindow
                    (\userReload ->
                        [ userReload.portEvent 10 "user_agent_from_js" (Json.Encode.string firefoxDesktop)
                        , hasExactText userReload [ "2" ]
                        ]
                    )
                ]
            )
        ]
    , T.start
        "Guild icon notification is shown"
        startTime
        normalConfig
        [ connectTwoUsersAndJoinNewGuild
            (\admin user ->
                [ user.click 100 (Dom.id "guildIcon_showFriends")
                , writeMessage admin "See if notification appears next to guild icon"
                , user.snapshotView 100 { name = "Guild icon new message notification" }
                , T.connectFrontend
                    100
                    sessionId1
                    (Route.encode Route.HomePageRoute)
                    desktopWindow
                    (\_ ->
                        [ user.snapshotView 100 { name = "Guild icon new message notification on reload" } ]
                    )
                , writeMessage admin "@Stevie Steve now you should see a red icon"
                , user.snapshotView 100 { name = "Guild icon new mention notification" }
                ]
            )
        ]
    , T.start
        "No messages missing even in long chat history"
        startTime
        normalConfig
        [ connectTwoUsersAndJoinNewGuild
            (\_ user ->
                [ List.range 0 (VisibleMessages.pageSize * 2)
                    |> List.map (\index -> writeMessage user ("Message " ++ String.fromInt (index + 1)))
                    |> T.group
                , T.connectFrontend
                    100
                    sessionId1
                    (Route.encode Route.HomePageRoute)
                    desktopWindow
                    (\userReload ->
                        [ userReload.portEvent 10 "user_agent_from_js" (Json.Encode.string firefoxDesktop)
                        , userReload.click 100 (Dom.id "guild_openGuild_1")
                        , writeMessage userReload "Another message"
                        , userReload.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "Another message" ])
                        , hasNotExactText userReload [ "This is the start of #general", "Message 31" ]
                        , hasExactText userReload [ "Message 32", "Message 61" ]
                        , noMissingMessages 100 userReload
                        , scrollToTop userReload
                        , userReload.checkView
                            100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.exactText "This is the start of #general"
                                , Test.Html.Selector.exactText "Message 1"
                                ]
                            )
                        , userReload.checkView
                            0
                            (Test.Html.Query.has
                                [ Test.Html.Selector.exactText "Message 2"
                                , Test.Html.Selector.exactText "Message 61"
                                ]
                            )
                        , noMissingMessages 100 userReload
                        , scrollToMiddle userReload
                        , userReload.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "This is the start of #general" ])
                        , scrollToTop userReload
                        , userReload.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "This is the start of #general" ])
                        , T.backendUpdate
                            5000
                            (Types.UserDisconnected sessionId1 userReload.clientId)
                        , T.backendUpdate
                            100
                            (Types.UserConnected sessionId1 userReload.clientId)
                        , userReload.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "Another message" ])
                        ]
                    )
                ]
            )
        ]
    , T.start
        "Notifications"
        startTime
        normalConfig
        [ connectTwoUsersAndJoinNewGuild
            (\admin user ->
                [ admin.input 100 (Dom.id "channel_textinput") "@Stevie Steve Hi!"
                , user.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.exactText "AT is typing..." ]
                    )
                , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                , user.checkView
                    100
                    (Test.Html.Query.hasNot
                        [ Test.Html.Selector.exactText "AT is typing..." ]
                    )
                , checkNoNotification "@Stevie Steve Hi!"
                , enableNotifications False admin
                , user.mouseEnter 100 (Dom.id "guild_message_1") ( 10, 10 ) []
                , user.custom
                    100
                    (Dom.id "miniView_reply")
                    "click"
                    (Json.Encode.object
                        [ ( "clientX", Json.Encode.int 300 )
                        , ( "clientY", Json.Encode.int 300 )
                        ]
                    )
                , user.input 100 (Dom.id "channel_textinput") "Hello admin!"
                , admin.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.exactText "Stevie Steve is typing..." ]
                    )
                , user.click 100 (Dom.id "messageMenu_channelInput_sendMessage")
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot
                        [ Test.Html.Selector.exactText "Stevie Steve is typing..." ]
                    )
                , checkNoNotification "Hello admin!"
                , createThread admin (Id.fromInt 2)
                , admin.input 100 (Dom.id "channel_textinput") "Lets move this to a thread..."
                , user.checkView
                    100
                    (Test.Html.Query.hasNot
                        [ Test.Html.Selector.exactText "AT is typing..." ]
                    )
                , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                , checkNotification "Lets move this to a thread..."
                , user.click 100 (Dom.id "guild_threadStarterIndicator_2")
                , admin.click 100 (Dom.id "guild_openDm_1")
                , writeMessage admin "Here's a DM to you"
                , user.click 100 (Dom.id "guildsColumn_openDm_0")
                , writeMessage user "Here's a reply!"
                , writeMessage user "And another reply"
                , user.update 100 (Types.VisibilityChanged Hidden)
                , T.connectFrontend
                    100
                    sessionId1
                    (Route.encode Route.HomePageRoute)
                    desktopWindow
                    (\userReload ->
                        [ userReload.portEvent 10 "user_agent_from_js" (Json.Encode.string firefoxDesktop)
                        , userReload.checkView
                            100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.id "guildsColumn_openDm_0" ]
                            )
                        , userReload.click 100 (Dom.id "guildIcon_showFriends")
                        , userReload.click 100 (Dom.id "guild_friendLabel_0")
                        , noMissingMessages 20 userReload
                        , userReload.click 100 (Dom.id "guild_openGuild_1")
                        , noMissingMessages 20 userReload
                        , userReload.click 100 (Dom.id "guild_openChannel_0")
                        , noMissingMessages 20 userReload
                        ]
                    )
                ]
            )
        ]
    , T.start
        "Enable 2FA"
        startTime
        normalConfig
        [ T.connectFrontend
            100
            sessionId0
            "/"
            desktopWindow
            (\user ->
                [ handleLogin firefoxDesktop adminEmail user
                , user.click 100 (Dom.id "guild_showUserOptions")
                , user.click 100 (Dom.id "userOverview_start2FaSetup")
                , user.snapshotView 100 { name = "2FA setup" }
                , user.input 100 (Dom.id "userOverview_twoFactorCodeInput") "123123"
                , user.snapshotView 100 { name = "2FA setup with wrong code" }
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
                                                , user.snapshotView 100 { name = "2FA setup complete" }
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
            desktopWindow
            (\user ->
                [ handleLogin firefoxDesktop adminEmail user
                , user.snapshotView 100 { name = "2FA login step" }
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
                                                , user.snapshotView 100 { name = "user overview with two factor already complete" }
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
    , T.start "Logins are rate limited"
        startTime
        normalConfig
        [ T.connectFrontend
            100
            sessionId0
            "/"
            desktopWindow
            (\user ->
                let
                    openLoginAndSubmitEmail delay =
                        T.group
                            [ user.click delay Pages.Home.loginButtonId
                            , user.input 100 LoginForm.emailInputId (EmailAddress.toString adminEmail)
                            , user.click 100 LoginForm.submitEmailButtonId
                            ]

                    tooManyIncorrectAttempts : List Test.Html.Selector.Selector
                    tooManyIncorrectAttempts =
                        [ Test.Html.Selector.text "Too many incorrect attempts." ]
                in
                [ user.portEvent 10 "user_agent_from_js" (Json.Encode.string firefoxDesktop)
                , openLoginAndSubmitEmail 100
                , List.range 0 9
                    |> List.map
                        (\index ->
                            [ user.checkView 100 (Test.Html.Query.hasNot tooManyIncorrectAttempts)
                            , user.input
                                100
                                LoginForm.loginCodeInputId
                                (String.padLeft LoginForm.loginCodeLength '0' (String.fromInt index))
                            ]
                                |> T.group
                        )
                    |> T.group
                , user.checkView 100 (Test.Html.Query.has tooManyIncorrectAttempts)
                , user.snapshotView 100 { name = "Too many incorrect attempts" }
                , T.andThen
                    100
                    (\data ->
                        case List.filterMap (isLoginEmail adminEmail) data.httpRequests of
                            loginCode :: _ ->
                                [ user.input 100 LoginForm.loginCodeInputId (String.fromInt loginCode) ]

                            _ ->
                                [ T.checkState 100 (\_ -> Err "Didn't find login email") ]
                    )
                , user.checkView 100 (Test.Html.Query.has tooManyIncorrectAttempts)
                , [ hasNotText user [ "Too many login attempts have been made." ]
                  , openLoginAndSubmitEmail 100
                  ]
                    |> T.group
                    |> List.repeat 6
                    |> T.group
                , hasText user [ "Too many login attempts have been made." ]
                , user.snapshotView 100 { name = "Too many login attempts" }
                , -- Should be able to log in again after some time has passed
                  openLoginAndSubmitEmail (5 * 60 * 1000)
                , T.andThen
                    100
                    (\data ->
                        case List.filterMap (isLoginEmail adminEmail) data.httpRequests of
                            loginCode :: _ ->
                                [ user.input 100 LoginForm.loginCodeInputId (String.fromInt loginCode) ]

                            _ ->
                                [ T.checkState 100 (\_ -> Err "Didn't find login email") ]
                    )
                , hasExactText user [ PersonName.toString Backend.adminUser.name ]
                ]
            )
        , T.checkState
            (Duration.hours 4.01 |> Duration.inMilliseconds)
            (\data ->
                case List.filterMap (isLogErrorEmail Env.adminEmail) data.httpRequests of
                    [ "LoginsRateLimited" ] ->
                        Ok ()

                    _ ->
                        Err "Expected to only see LoginsRateLimited as an error email"
            )
        ]
    , T.start "Test login"
        startTime
        normalConfig
        [ T.connectFrontend
            100
            sessionId0
            "/"
            desktopWindow
            (\client ->
                [ client.portEvent 10 "user_agent_from_js" (Json.Encode.string firefoxDesktop)
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
    , T.start
        "Add and remove reaction emojis"
        (Time.millisToPosix 1756739527046)
        normalConfig
        [ T.connectFrontend
            0
            (Lamdera.sessionIdFromString "24334c04b8f7b594cdeedebc2a8029b82943b0a6")
            "/"
            { width = 1887, height = 770 }
            (\tabA ->
                [ tabA.portEvent 8 "check_notification_permission_from_js" (Json.Encode.string "granted")
                , tabA.portEvent 1 "check_pwa_status_from_js" (stringToJson "false")
                , tabA.portEvent
                    1
                    "user_agent_from_js"
                    (Json.Encode.string "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0")
                , tabA.portEvent 19 "load_user_settings_from_js" (Json.Encode.string "")
                , T.connectFrontend
                    17
                    (Lamdera.sessionIdFromString "24334c04b8f7b594cdeedebc2a8029b82943b0a6")
                    "/"
                    { width = 1887, height = 674 }
                    (\tabB ->
                        [ tabB.portEvent 11 "check_notification_permission_from_js" (Json.Encode.string "granted")
                        , tabB.portEvent 0 "check_pwa_status_from_js" (stringToJson "false")
                        , tabB.portEvent
                            1
                            "user_agent_from_js"
                            (Json.Encode.string "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0")
                        , tabB.portEvent 8 "load_user_settings_from_js" (Json.Encode.string "")
                        , tabA.click 3098 (Dom.id "homePage_loginButton")
                        , tabA.input 1916 (Dom.id "loginForm_emailInput") "a@a.se"
                        , tabA.keyUp 263 (Dom.id "loginForm_emailInput") "Enter" []
                        , tabA.input 164 (Dom.id "loginForm_loginCodeInput") "22923193"
                        , tabA.input 1 (Dom.id "loginForm_loginCodeInput") "22923193"
                        , tabA.click 1747 (Dom.id "guild_openGuild_0")
                        , writeMessage tabA "Test"
                        , tabB.click 111 (Dom.id "guild_openGuild_0")
                        , tabB.focus 25 (Dom.id "channel_textinput")
                        , tabA.mouseEnter 991 (Dom.id "guild_message_0") ( 620, 54 ) []
                        , tabA.focus 921 (Dom.id "channel_textinput")
                        , tabA.blur 4 (Dom.id "channel_textinput")
                        , tabB.blur 17 (Dom.id "channel_textinput")
                        , tabA.click 28 (Dom.id "miniView_reply")
                        , tabA.focus 8 (Dom.id "channel_textinput")
                        , tabA.mouseLeave 375 (Dom.id "guild_message_0") ( 1286, 57 ) []
                        , tabA.click 457 (Dom.id "channel_textinput")
                        , tabA.input 781 (Dom.id "channel_textinput") "Test2"
                        , tabA.blur 2357 (Dom.id "channel_textinput")
                        , tabA.click 78 (Dom.id "messageMenu_channelInput_sendMessage")
                        , T.collapsableGroup
                            "Add emoji to guild channel message"
                            [ tabA.mouseEnter 1 (Dom.id "guild_message_0") ( 1036, 55 ) []
                            , tabA.click 1205 (Dom.id "miniView_showReactionEmojiSelector")
                            , tabA.mouseLeave 633 (Dom.id "guild_message_0") ( 690, -1 ) []
                            , tabA.click 991 (Dom.id "guild_emojiSelector_😀")
                            , tabB.checkView 50 (Test.Html.Query.has [ Test.Html.Selector.exactText "😀" ])
                            , tabA.mouseEnter 348 (Dom.id "guild_message_0") ( 66, 13 ) []
                            , tabA.click 548 (Dom.id "guild_removeReactionEmoji_0")
                            , tabB.checkView 50 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "😀" ])
                            , tabA.click 100 (Dom.id "miniView_emojiReact_0")
                            , tabB.checkView 50 (Test.Html.Query.has [ Test.Html.Selector.exactText "😀" ])
                            , tabA.click 100 (Dom.id "miniView_emojiReact_0")
                            , tabB.checkView 50 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "😀" ])
                            , tabA.mouseLeave 410 (Dom.id "guild_message_0") ( 148, 63 ) []
                            ]
                        , createThread tabA (Id.fromInt 0)
                        , tabA.mouseEnter 1 (Dom.id "guild_message_0") ( 1036, 55 ) []
                        , tabA.click 1205 (Dom.id "miniView_showReactionEmojiSelector")
                        , tabA.mouseLeave 633 (Dom.id "guild_message_0") ( 690, -1 ) []
                        , tabA.click 991 (Dom.id "guild_emojiSelector_😀")
                        , tabB.checkView 50 (Test.Html.Query.has [ Test.Html.Selector.exactText "😀" ])
                        , tabA.mouseEnter 348 (Dom.id "guild_message_0") ( 66, 13 ) []
                        , tabA.click 548 (Dom.id "guild_removeReactionEmoji_0")
                        , tabB.checkView 50 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "😀" ])
                        , tabA.mouseLeave 410 (Dom.id "guild_message_0") ( 148, 63 ) []
                        , tabA.click 457 (Dom.id "channel_textinput")
                        , tabA.input 781 (Dom.id "channel_textinput") "Test3"
                        , tabA.blur 2357 (Dom.id "channel_textinput")
                        , tabA.click 78 (Dom.id "messageMenu_channelInput_sendMessage")
                        , tabB.click 100 (Dom.id "guild_viewThread_0_0")
                        , tabA.mouseEnter 1 (Dom.id "thread_message_0") ( 1036, 55 ) []
                        , tabA.click 1205 (Dom.id "miniView_showReactionEmojiSelector")
                        , tabA.mouseLeave 633 (Dom.id "thread_message_0") ( 690, -1 ) []
                        , tabA.click 100 (Dom.id "emoji_category_People & Body")
                        , tabA.click 991 (Dom.id "guild_emojiSelector_👍")
                        , tabB.checkView 50 (Test.Html.Query.has [ Test.Html.Selector.exactText "👍" ])
                        , tabA.mouseEnter 348 (Dom.id "thread_message_0") ( 66, 13 ) []
                        , tabA.click 548 (Dom.id "guild_removeReactionEmoji_0")
                        , tabB.checkView 50 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "👍" ])
                        , tabA.click 100 (Dom.id "miniView_emojiReact_1")
                        , tabB.checkView 50 (Test.Html.Query.has [ Test.Html.Selector.exactText "👍" ])
                        , tabA.click 100 (Dom.id "miniView_emojiReact_1")
                        , tabB.checkView 50 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "👍" ])
                        , tabA.mouseLeave 410 (Dom.id "thread_message_0") ( 148, 63 ) []
                        ]
                    )
                ]
            )
        ]
    , T.start
        "Opening non-existent guild shouldn't show \"Unable to reach the server.\" warning"
        (Time.millisToPosix 1757158297558)
        normalConfig
        [ T.connectFrontend
            0
            (Lamdera.sessionIdFromString "207950c04b8f7b594cdeedebc2a8029b82943b0a")
            "/g/1/c/0"
            { width = 1615, height = 820 }
            (\tab1 ->
                [ tab1.portEvent 10 "check_notification_permission_from_js" (Json.Encode.string "granted")
                , tab1.portEvent 1 "check_pwa_status_from_js" (stringToJson "false")
                , tab1.portEvent
                    1
                    "user_agent_from_js"
                    (Json.Encode.string "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0")
                , tab1.portEvent 990 "load_user_settings_from_js" (Json.Encode.string "")
                , tab1.input 2099 (Dom.id "loginForm_emailInput") "a@a.se"
                , tab1.keyUp 286 (Dom.id "loginForm_emailInput") "Enter" []
                , tab1.input 91 (Dom.id "loginForm_loginCodeInput") "22923193"
                , tab1.input 1 (Dom.id "loginForm_loginCodeInput") "22923193"
                , tab1.click 17660 (Dom.id "guild_openGuild_0")
                , tab1.focus 17 (Dom.id "channel_textinput")
                , tab1.blur 3994 (Dom.id "channel_textinput")
                , tab1.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Unable to reach the server." ])
                ]
            )
        ]
    , T.start
        "Export and import backend round-trip"
        startTime
        (T.Config
            Frontend.app_
            Backend.app_
            (handleNormalHttpRequests (\_ -> Nothing))
            handlePortToJs
            (\requestData ->
                case requestData.data.downloads of
                    [ backup ] ->
                        case backup.content of
                            T.BytesFile bytes ->
                                UploadFile
                                    (T.uploadBytesFile backup.filename backup.mimeType bytes startTime)

                            T.StringFile _ ->
                                UnhandledFileUpload

                    _ ->
                        UnhandledFileUpload
            )
            handleMultiFileUpload
            domain
        )
        [ connectTwoUsersAndJoinNewGuild
            (\admin user ->
                [ writeMessage admin "Hello export test!"
                , user.click 100 (Dom.id "guild_openDm_0")
                , writeMessage user "Hello!"
                , linkDiscordAndLogin
                    (Lamdera.sessionIdFromString "JoeSession")
                    "Joe"
                    joeEmail
                    True
                    discordOp0Ready
                    discordOp0ReadySupplemental
                    (\_ -> [])
                , admin.click 100 (Dom.id "guild_showUserOptions")
                , admin.click 100 (Dom.id "userOptions_gotoAdmin")
                , admin.click 100 (Dom.id "admin_expandSectionButton_Export/Import")
                , T.andThen
                    100
                    (\beforeExportData ->
                        [ admin.click 100 (Dom.id "admin_exportBackendButton")
                        , admin.click 100 (Dom.id "admin_expandSectionButton_Guilds")
                        , admin.click 100 (Dom.id "admin_expandSectionButton_Users")
                        , admin.click 100 (Dom.id "admin_expandSectionButton_Discord guilds")
                        , admin.click 100 (Dom.id "admin_expandSectionButton_Discord DM channels")
                        , T.andThen
                            100
                            (\data ->
                                let
                                    deleteGuildActions =
                                        SeqDict.keys data.backend.guilds
                                            |> List.map
                                                (\guildId ->
                                                    admin.click 100 (Dom.id ("Admin_deleteGuildButton_" ++ Id.toString guildId))
                                                )

                                    deleteUserActions =
                                        NonemptyDict.toList data.backend.users
                                            |> List.filterMap
                                                (\( userId, backendUser ) ->
                                                    if backendUser.isAdmin then
                                                        Nothing

                                                    else
                                                        Just (admin.click 100 (Dom.id ("Admin_deleteUserButton_a_" ++ Id.toString userId ++ "_")))
                                                )
                                in
                                deleteGuildActions
                                    ++ deleteUserActions
                                    ++ [ admin.click 100 (Dom.id "admin_saveUserChangesButton")
                                       , admin.click 100 (Dom.id "Admin_deleteDiscordGuildButton_705745250815311942")
                                       , admin.click 100 (Dom.id "Admin_deleteDiscordDmChannelButton_185574444641550336")
                                       , admin.click 100 (Dom.id "Admin_deleteDiscordDmChannelButton_222087308516524036")
                                       , admin.click 100 (Dom.id "Admin_deleteDiscordDmChannelButton_1215077285749858324")
                                       ]
                                    |> T.collapsableGroup "Delete stuff"
                                    |> List.singleton
                            )
                        , admin.click 300 (Dom.id "admin_importBackendButton")
                        , admin.checkView
                            500
                            (Test.Html.Query.has [ Test.Html.Selector.text "Imported!" ])
                        , T.checkState
                            100
                            (\afterImportData ->
                                if
                                    (beforeExportData.backend.guilds == afterImportData.backend.guilds)
                                        && (beforeExportData.backend.dmChannels == afterImportData.backend.dmChannels)
                                        && (beforeExportData.backend.discordGuilds == afterImportData.backend.discordGuilds)
                                        && (beforeExportData.backend.discordDmChannels == afterImportData.backend.discordDmChannels)
                                        && (beforeExportData.backend.users == afterImportData.backend.users)
                                        && (beforeExportData.backend.discordUsers == afterImportData.backend.discordUsers)
                                then
                                    Ok ()

                                else
                                    Err "Expected at least one guild in backend after import"
                            )
                        ]
                    )
                ]
            )
        ]
    ]


checkNoErrorLogs : T.Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
checkNoErrorLogs =
    T.checkState
        100
        (\data ->
            case List.filterMap (isLogErrorEmail Env.adminEmail) data.httpRequests of
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
    T.start
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
                        , writeMessage user "Hello"
                        , admin.click 100 (Dom.id "guildsColumn_openDm_1")
                        , writeMessage user "Hello 2"
                        , writeMessage admin "Hello from *admin*"
                        , user.checkView
                            100
                            (\html ->
                                Test.Html.Query.findAll [ Test.Html.Selector.exactText "Sven" ] html
                                    |> Test.Html.Query.count (Expect.equal 2)
                            )
                        ]
                    )
                ]
            )
        ]


attackerTriesToLeakSensitiveData :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
attackerTriesToLeakSensitiveData config =
    T.start
        "Attacker tries to leak/modify sensitive data"
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
                        [ writeMessage user "sensitive guild message"
                        , admin.click 100 (Dom.id "guild_openChannel_0")
                        , writeMessage admin "sensitive guild message 2"
                        , user.click 1000 (Dom.id "guild_openDm_0")
                        , writeMessage user "sensitive DM message"
                        , T.connectFrontend
                            100
                            sessionId2
                            "/"
                            desktopWindow
                            (\attacker ->
                                [ handleLogin chromeDesktop joeEmail attacker
                                , attacker.update 0 Types.EnableToFrontendLogging
                                , attacker.input 100 (Dom.id "loginForm_name") "Attacker"
                                , attacker.click 100 (Dom.id "loginForm_submit")
                                , T.andThen
                                    100
                                    (\before ->
                                        let
                                            attackerUserId : Id UserId
                                            attackerUserId =
                                                Id.fromInt 2

                                            guildId : Id GuildId
                                            guildId =
                                                Id.fromInt 0
                                        in
                                        [ List.indexedMap
                                            (\index localChange ->
                                                attacker.sendToBackend 100 (LocalModelChangeRequest (ChangeId index) localChange)
                                            )
                                            attackerLocalChanges
                                            |> T.collapsableGroup "attacks"
                                        , List.map (attacker.sendToBackend 100) attackerToBackendChanges
                                            |> T.collapsableGroup "attacks"
                                        , T.checkState
                                            500
                                            (\after ->
                                                let
                                                    errors : List String
                                                    errors =
                                                        (if SeqDict.get guildId before.backend.guilds == SeqDict.get guildId after.backend.guilds then
                                                            []

                                                         else
                                                            [ "Guild data was modified by attacker" ]
                                                        )
                                                            ++ (if before.backend.dmChannels == after.backend.dmChannels then
                                                                    []

                                                                else
                                                                    [ "DM channels were modified by attacker" ]
                                                               )
                                                            ++ (if NonemptyDict.remove attackerUserId before.backend.users == NonemptyDict.remove attackerUserId after.backend.users then
                                                                    []

                                                                else
                                                                    [ "Users were modified by attacker" ]
                                                               )
                                                            ++ (if before.backend.privateVapidKey == after.backend.privateVapidKey then
                                                                    []

                                                                else
                                                                    [ "Private VAPID key was modified by attacker" ]
                                                               )
                                                            ++ (if before.backend.slackClientSecret == after.backend.slackClientSecret then
                                                                    []

                                                                else
                                                                    [ "Slack client secret was modified by attacker" ]
                                                               )
                                                            ++ (if before.backend.openRouterKey == after.backend.openRouterKey then
                                                                    []

                                                                else
                                                                    [ "OpenRouter key was modified by attacker" ]
                                                               )
                                                            ++ (if before.backend.emailNotificationsEnabled == after.backend.emailNotificationsEnabled then
                                                                    []

                                                                else
                                                                    [ "Email notifications setting was modified by attacker" ]
                                                               )
                                                in
                                                case errors of
                                                    [] ->
                                                        Ok ()

                                                    _ ->
                                                        Err (String.join "; " errors)
                                            )
                                        , attacker.checkModel
                                            100
                                            (\model ->
                                                case model of
                                                    Types.Loaded loaded ->
                                                        case loaded.toFrontendLogs of
                                                            Just toFrontendLogs ->
                                                                let
                                                                    invalidToFrontends : Array ToFrontend
                                                                    invalidToFrontends =
                                                                        Array.filter attackerShouldNotGetThisToFrontend toFrontendLogs
                                                                in
                                                                if Array.isEmpty invalidToFrontends then
                                                                    Ok ()

                                                                else
                                                                    Array.toList invalidToFrontends
                                                                        |> List.map
                                                                            (\invalid ->
                                                                                Debug.toString invalid
                                                                            )
                                                                        |> String.join ", "
                                                                        |> (\a -> "The attacker received ToFrontend with potentially sensitive info: " ++ a)
                                                                        |> Err

                                                            Nothing ->
                                                                Err "Should have been logging toFrontend"

                                                    Types.Loading _ ->
                                                        Err "Attacker didn't load for some reason"
                                            )
                                        ]
                                    )
                                ]
                            )
                        ]
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

        LocalChangeResponse _ _ ->
            False

        ChangeBroadcast localMsg ->
            case localMsg of
                Types.LocalChange _ _ ->
                    True

                Types.ServerChange serverChange ->
                    case serverChange of
                        Types.Server_SendMessage _ _ _ _ _ _ ->
                            True

                        --RichText.toString SeqDict.empty message |> String.contains "sensitive"
                        Types.Server_Discord_SendMessage _ _ _ _ _ ->
                            True

                        Types.Server_NewChannel _ _ _ ->
                            True

                        Types.Server_EditChannel _ _ _ ->
                            True

                        Types.Server_DeleteChannel _ _ ->
                            True

                        Types.Server_NewInviteLink _ _ _ _ ->
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

                        Types.Server_PushNotificationFailed _ ->
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

        TwoFactorAuthenticationToFrontend _ ->
            False

        AiChatToFrontend _ ->
            False

        YouConnected ->
            True

        ReloadDataResponse _ ->
            False

        LinkDiscordResponse _ ->
            False

        ProfilePictureEditorToFrontend _ ->
            False


attackerToBackendChanges : List ToBackend
attackerToBackendChanges =
    [ CheckLoginRequest InitialLoadRequested_None
    , LoginWithTokenRequest InitialLoadRequested_None 0 UserAgent.init
    , LoginWithTwoFactorRequest InitialLoadRequested_None 0 UserAgent.init
    , GetLoginTokenRequest (Unsafe.emailAddress "attacker@example.com")
    , AdminToBackend (Pages.Admin.ExportBackendRequest Pages.Admin.ExportAll)
    , LocalModelChangeRequest (ChangeId 0) Local_Invalid
    , TwoFactorToBackend TwoFactorAuthentication.EnableTwoFactorAuthenticationRequest
    , JoinGuildByInviteRequest (Id.fromInt 0) (SecretId "fake-invite-link")
    , FinishUserCreationRequest InitialLoadRequested_None (Unsafe.personName "hacked") UserAgent.init
    , AiChatToBackend (AiChat.AiMessageRequestSimple "model" (AiChat.RespondId 0) "hacked")
    , ReloadDataRequest InitialLoadRequested_None
    , LinkSlackOAuthCode (Slack.OAuthCode "fake-code") (SessionIdHash "fake-hash")
    , LinkDiscordRequest discordUserAuth
    , ProfilePictureEditorToBackend (ImageEditor.ChangeUserAvatarRequest (FileStatus.FileHash "fake-hash"))
    , AdminDataRequest Nothing
    , -- Make sure this one is last
      LogOutRequest
    ]


attackerLocalChanges : List LocalChange
attackerLocalChanges =
    let
        normalUserId : Id UserId
        normalUserId =
            Id.fromInt 1

        guildId : Id GuildId
        guildId =
            Id.fromInt 0

        channelId : Id ChannelId
        channelId =
            Id.fromInt 0

        messageTime =
            Time.millisToPosix 99999

        normalText =
            Nonempty (NormalText 'h' "acked") []

        discordUserId =
            Discord.idFromUInt64 (Unsafe.uint64 "0")

        discordGuildId =
            Discord.idFromUInt64 (Unsafe.uint64 "0")

        discordChannelId =
            Discord.idFromUInt64 (Unsafe.uint64 "0")

        discordPrivateChannelId =
            Discord.idFromUInt64 (Unsafe.uint64 "0")

        guildOrDmId_dm : AnyGuildOrDmId
        guildOrDmId_dm =
            GuildOrDmId_Dm normalUserId |> GuildOrDmId

        guildOrDmId_guild : AnyGuildOrDmId
        guildOrDmId_guild =
            GuildOrDmId_Guild guildId channelId |> GuildOrDmId

        discordGuildOrDmId : DiscordGuildOrDmId
        discordGuildOrDmId =
            DiscordGuildOrDmId_Guild discordUserId discordGuildId discordChannelId

        threadRouteWithMessage =
            NoThreadWithMessage (Id.fromInt 0)

        threadRouteWithMaybeMessage =
            NoThreadWithMaybeMessage (Just (Id.fromInt 0))

        emoji =
            Emoji.UnicodeEmoji "👍"

        discordDmData : DiscordGuildOrDmId_DmData
        discordDmData =
            { currentUserId = discordUserId
            , channelId = discordPrivateChannelId
            }
    in
    [ Local_AddReactionEmoji guildOrDmId_dm threadRouteWithMessage emoji
    , Local_AddReactionEmoji guildOrDmId_guild threadRouteWithMessage emoji
    , Local_Admin (Pages.Admin.SetSignupsEnabled True)
    , Local_CurrentlyViewing StopViewingChannel
    , Local_DeleteChannel guildId channelId
    , Local_DeleteMessage guildOrDmId_dm threadRouteWithMessage
    , Local_DeleteMessage guildOrDmId_guild threadRouteWithMessage
    , Local_Discord_LoadChannelMessages discordGuildOrDmId (Id.fromInt 0) EmptyPlaceholder
    , Local_Discord_LoadThreadMessages discordGuildOrDmId (Id.fromInt 0) (Id.fromInt 0) EmptyPlaceholder
    , Local_Discord_SendEditDmMessage messageTime discordDmData (Id.fromInt 0) (Nonempty (NormalText 'h' "acked") [])
    , Local_Discord_SendEditGuildMessage messageTime discordUserId discordGuildId discordChannelId threadRouteWithMessage (Nonempty (NormalText 'h' "acked") [])
    , Local_Discord_SendMessage messageTime discordGuildOrDmId (Nonempty (NormalText 'h' "acked") []) threadRouteWithMaybeMessage SeqDict.empty
    , Local_EditChannel guildId channelId (Unsafe.channelName "hacked")
    , Local_Invalid
    , Local_LinkDiscordAcknowledgementIsChecked True
    , Local_LoadChannelMessages (GuildOrDmId_Dm normalUserId) (Id.fromInt 0) EmptyPlaceholder
    , Local_LoadThreadMessages (GuildOrDmId_Dm normalUserId) (Id.fromInt 0) (Id.fromInt 0) EmptyPlaceholder
    , Local_MemberEditTyping messageTime guildOrDmId_dm threadRouteWithMessage
    , Local_MemberTyping messageTime ( guildOrDmId_dm, NoThread )
    , Local_LoadChannelMessages (GuildOrDmId_Guild guildId channelId) (Id.fromInt 0) EmptyPlaceholder
    , Local_LoadThreadMessages (GuildOrDmId_Guild guildId channelId) (Id.fromInt 0) (Id.fromInt 0) EmptyPlaceholder
    , Local_MemberEditTyping messageTime guildOrDmId_guild threadRouteWithMessage
    , Local_MemberTyping messageTime ( guildOrDmId_guild, NoThread )
    , Local_NewChannel messageTime guildId (Unsafe.channelName "hacked")
    , Local_NewGuild messageTime (Unsafe.guildName "hacked") EmptyPlaceholder
    , Local_NewInviteLink messageTime guildId EmptyPlaceholder
    , Local_RegisterPushSubscription { endpoint = domain, auth = "auth", p256dh = "p256dh" }
    , Local_RemoveReactionEmoji guildOrDmId_guild threadRouteWithMessage emoji
    , Local_SendEditMessage messageTime (GuildOrDmId_Dm normalUserId) threadRouteWithMessage normalText SeqDict.empty
    , Local_SendMessage messageTime (GuildOrDmId_Guild guildId channelId) normalText threadRouteWithMaybeMessage SeqDict.empty
    , Local_RemoveReactionEmoji guildOrDmId_dm threadRouteWithMessage emoji
    , Local_SendEditMessage messageTime (GuildOrDmId_Dm normalUserId) threadRouteWithMessage normalText SeqDict.empty
    , Local_SendMessage messageTime (GuildOrDmId_Guild guildId channelId) normalText threadRouteWithMaybeMessage SeqDict.empty
    , Local_SetDiscordGuildNotificationLevel discordGuildId User.NotifyOnEveryMessage
    , Local_SetDomainWhitelist True (Domain "example.com")
    , Local_SetEmojiCategory Emoji.Activities
    , Local_SetEmojiSkinTone (Just Emoji.SkinTone1)
    , Local_SetGuildNotificationLevel guildId User.NotifyOnEveryMessage
    , Local_SetLastViewed guildOrDmId_guild threadRouteWithMessage
    , Local_SetLastViewed guildOrDmId_dm threadRouteWithMessage
    , Local_SetName (Unsafe.personName "hacked")
    , Local_SetNotificationMode NoNotifications
    , Local_StartReloadingDiscordUser messageTime discordUserId
    , Local_TextEditor TextEditor.Local_Reset
    , Local_UnlinkDiscordUser discordUserId
    ]
