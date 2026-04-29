module RecordedTests exposing (main, setup)

import AiChat exposing (AiModelName(..))
import Array exposing (Array)
import Backend
import Broadcast
import Bytes exposing (Bytes)
import Codec
import Coord
import CustomEmoji
import Dict
import Discord
import Duration
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Browser.Events exposing (Visibility(..))
import Effect.Lamdera as Lamdera exposing (SessionId)
import Effect.Test as T exposing (DelayInMs, FileUpload(..), HttpRequest, HttpResponse(..), MultipleFilesUpload(..), RequestedBy(..))
import Effect.Websocket as Websocket
import EmailAddress exposing (EmailAddress)
import Emoji exposing (Category(..), EmojiOrCustomEmoji(..), SkinTone(..))
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
import Local exposing (ChangeId(..))
import LoginForm
import MessageInput
import NonemptyDict
import Pages.Admin
import Pages.Guild
import Pages.Home
import Parser exposing ((|.), (|=))
import PersonName
import Range exposing (Range)
import RateLimit
import RichText exposing (Domain(..))
import Route
import SafeJson exposing (SafeJson(..))
import SecretId exposing (SecretId(..))
import SeqDict
import SessionIdHash exposing (SessionIdHash(..))
import Slack
import Sticker
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
import VisibleMessages


setup : T.ViewerWith (List (T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel))
setup =
    T.viewerWith tests
        |> T.addStringFile "/tests/data/discord-op0-ready.json"
        |> T.addStringFile "/tests/data/discord-op0-ready-supplemental.json"
        |> T.addStringFile "/tests/data/discord-sticker-packs.json"
        |> T.addBytesFile "/tests/data/at-user-icon.png"
        |> T.addStringFile "/public/compact-emoji.json"


main : Program () (T.Model ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel) (T.Msg ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
main =
    T.startViewer setup


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


handleCustomRequest : String -> CustomRequest -> HttpResponse
handleCustomRequest discordStickerPacks { method, url, headers, body } =
    if String.startsWith "https://" url then
        case ( method, String.dropLeft 8 url |> String.split "/" ) of
            ( "GET", [ "discord.com", "api", "v9", "users", "@me" ] ) ->
                if List.Extra.count (\a -> a == ( "Authorization", "legit-token" )) headers == 1 && body == Nothing then
                    StringHttpResponse
                        { url = url, statusCode = 200, statusText = "OK", headers = Dict.empty }
                        """{"id":"184437096813953035","username":"at28727","avatar":"7c40cb63ea11096169c5a4dcb5825a3d","discriminator":"0","public_flags":0,"flags":0,"banner":null,"accent_color":null,"global_name":"AT2","avatar_decoration_data":null,"collectibles":null,"display_name_styles":null,"banner_color":null,"clan":null,"primary_guild":null,"mfa_enabled":false,"locale":"en-US","premium_type":0,"email":"a@a.se","verified":true,"phone":null,"nsfw_allowed":null,"linked_users":[],"bio":"","authenticator_types":[],"age_verification_status":1}"""

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


tests :
    String
    -> String
    -> String
    -> Bytes
    -> String
    -> List (T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
tests discordOp0Ready discordOp0ReadySupplemental discordStickerPacks atUserIcon emojiJson =
    let
        handleNormalHttpRequests : ({ currentRequest : HttpRequest, data : T.Data FrontendModel BackendModel } -> Maybe HttpResponse) -> { currentRequest : HttpRequest, data : T.Data FrontendModel BackendModel } -> HttpResponse
        handleNormalHttpRequests overrides ({ currentRequest } as httpRequests) =
            case overrides httpRequests of
                Just response ->
                    response

                Nothing ->
                    case String.split "/" currentRequest.url of
                        [ "", "_i" ] ->
                            StringHttpResponse
                                { url = currentRequest.url
                                , statusCode = 200
                                , statusText = "OK"
                                , headers = Dict.empty
                                }
                                infoEndpointResponse

                        [ "", "compact-emoji.json" ] ->
                            StringHttpResponse
                                { url = currentRequest.url
                                , statusCode = 200
                                , statusText = "OK"
                                , headers = Dict.empty
                                }
                                emojiJson

                        "http:" :: "" :: "localhost:3000" :: "file" :: rest ->
                            case rest of
                                "internal" :: rest2 ->
                                    handleInternalRequests discordStickerPacks currentRequest rest2

                                [ "upload" ] ->
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

                                [ "upload-url" ] ->
                                    case currentRequest.body of
                                        T.JsonBody json ->
                                            case Codec.decodeValue FileStatus.uploadUrlCodec json of
                                                Ok request ->
                                                    -- Check if we are trying to upload a Discord standard sticker. We don't want those loaded by automated systems as they are copyrighted material
                                                    if String.contains "796138864933863456" request.url then
                                                        UnhandledHttpRequest

                                                    else
                                                        StringHttpResponse
                                                            { url = currentRequest.url
                                                            , statusCode = 200
                                                            , statusText = "OK"
                                                            , headers = Dict.empty
                                                            }
                                                            (Codec.encodeToString
                                                                0
                                                                FileStatus.uploadResponseCodec
                                                                { fileHash = FileStatus.fileHash request.url
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

                        [ "https:", "", "api.postmarkapp.com", "email" ] ->
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
    in
    [ attackerTriesToLeakSensitiveData normalConfig discordOp0Ready discordOp0ReadySupplemental
    , inviteUserAndDmChat normalConfig
    , startTest
        "Admin can open admin page"
        startTime
        normalConfig
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
    , startTest
        "Regenerate server secret button hits rust-server and applies response"
        startTime
        normalConfig
        [ T.connectFrontend
            100
            sessionId0
            "/"
            desktopWindow
            (\admin ->
                [ handleLogin firefoxDesktop adminEmail admin
                , admin.click 100 (Dom.id "guild_showUserOptions")
                , admin.click 100 (Dom.id "userOptions_gotoAdmin")
                , admin.click 100 (Dom.id "admin_expandSectionButton_API keys")
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Not regenerated" ])
                , admin.click 100 (Dom.id "admin_regenerateServerSecret")
                , T.checkState
                    100
                    (\data ->
                        case
                            List.filter
                                (\request ->
                                    (request.url == "http://localhost:3000/file/internal/regenerate-server-secret")
                                        && (request.method == "POST")
                                        && (request.requestedBy == RequestedByBackend)
                                        && List.member ( "x-secret-key", Env.secretKey ) request.headers
                                )
                                data.httpRequests
                        of
                            [ _ ] ->
                                Ok ()

                            [] ->
                                Err "Expected one POST to rust-server /file/internal/regenerate-server-secret"

                            _ ->
                                Err "Expected exactly one POST to rust-server /file/internal/regenerate-server-secret"
                    )
                , T.checkState
                    100
                    (\data ->
                        if SecretId.toString data.backend.serverSecret == regeneratedServerSecretValue then
                            Ok ()

                        else
                            Err
                                ("Backend server secret was not updated, got: "
                                    ++ SecretId.toString data.backend.serverSecret
                                )
                    )
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Last regenerated at " ])
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot
                        [ Test.Html.Selector.exactText "Not regenerated"
                        , Test.Html.Selector.exactText "Regenerating"
                        ]
                    )
                ]
            )
        ]
    , startTest
        "Create message with embeds and then edit that message"
        startTime
        normalConfig
        [ connectTwoUsersAndJoinNewGuild
            desktopWindow
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
                [ writeMessage admin 100 "Test https://elm.camp/ https://elm.camp/ https://meetdown.app/"
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
    , startTest
        "Friend label shows typing indicator"
        startTime
        normalConfig
        [ connectTwoUsersAndJoinNewGuild
            desktopWindow
            (\admin user ->
                [ admin.click 100 (Dom.id "guild_openDm_1")
                , writeMessage admin 100 "Hello from admin"
                , user.click 100 (Dom.id "guildIcon_showFriends")
                , user.checkView
                    100
                    (Test.Html.Query.hasNot
                        [ Test.Html.Selector.exactText "Typing...", Test.Html.Selector.exactText "Editing..." ]
                    )

                -- Admin types in DM, user sees "Typing..." but admin does not
                , admin.input 100 (Dom.id "channel_textinput") "I am typing"
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Typing..." ])
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Typing..." ])

                -- Admin sends the message, typing indicator disappears
                , admin.click 100 (Dom.id "guild_friendLabel_1")
                , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Typing..." ])

                -- Admin edits a message, user sees "Editing..." but admin does not
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
                , admin.input 200 (Dom.id "editMessageTextInput") "Edited message"
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Editing..." ])
                , admin.click 100 (Dom.id "guildIcon_showFriends")
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Editing..." ])

                -- Admin finishes editing, editing indicator disappears
                , admin.click 100 (Dom.id "guild_friendLabel_1")
                , admin.keyDown 100 (Dom.id "editMessageTextInput") "Enter" []
                , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Editing..." ])
                ]
            )
        ]
    , startTest
        "Emoji selector arrow key navigation"
        startTime
        normalConfig
        [ connectTwoUsersAndJoinNewGuild
            desktopWindow
            (\admin _ ->
                let
                    checkHover :
                        (Maybe Emoji.EmojiOrSticker -> Result String ())
                        -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
                    checkHover predicate =
                        admin.checkModel
                            100
                            (\model ->
                                case model of
                                    Types.Loaded loaded ->
                                        case loaded.loginStatus of
                                            Types.LoggedIn loggedIn ->
                                                predicate loggedIn.emojiSelector.emojiHovered

                                            _ ->
                                                Err "Admin isn't logged in"

                                    Types.Loading _ ->
                                        Err "Admin frontend didn't finish loading"
                            )

                    expectHovered : Maybe Emoji.EmojiOrSticker -> Maybe Emoji.EmojiOrSticker -> Result String ()
                    expectHovered expected actual =
                        if actual == expected then
                            Ok ()

                        else
                            Err ("Expected emojiHovered to be " ++ Debug.toString expected ++ " but was " ++ Debug.toString actual)

                    expectSomeHovered : Maybe Emoji.EmojiOrSticker -> Result String ()
                    expectSomeHovered actual =
                        case actual of
                            Just _ ->
                                Ok ()

                            Nothing ->
                                Err "Expected some emoji to be hovered but none was"
                in
                [ admin.click 100 (Dom.id "messageMenu_channelInput_openEmojiSelector")
                , checkHover (expectHovered Nothing)

                -- Left/right do nothing while no emoji is highlighted.
                , admin.keyDown 100 Emoji.searchInputId "ArrowRight" []
                , checkHover (expectHovered Nothing)
                , admin.keyDown 100 Emoji.searchInputId "ArrowLeft" []
                , checkHover (expectHovered Nothing)

                -- ArrowDown enters keyboard navigation and highlights the first emoji.
                , admin.keyDown 100 Emoji.searchInputId "ArrowDown" []
                , checkHover expectSomeHovered

                -- ArrowRight keeps navigation going while something is highlighted.
                , admin.keyDown 100 Emoji.searchInputId "ArrowRight" []
                , checkHover expectSomeHovered

                -- ArrowUp from the top row clears the highlight so the cursor
                -- is free again and no emoji is highlighted.
                , admin.keyDown 100 Emoji.searchInputId "ArrowUp" []
                , checkHover (expectHovered Nothing)

                -- ArrowDown then Enter selects and closes the selector.
                , admin.keyDown 100 Emoji.searchInputId "ArrowDown" []
                , checkHover expectSomeHovered
                , admin.keyDown 100 Emoji.searchInputId "Enter" []
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot
                        [ Test.Html.Selector.id (Dom.idToString Emoji.searchInputId) ]
                    )
                , T.andThen
                    100
                    (\data ->
                        case List.filter (\request -> request.portName == "exec_command_to_js") data.portRequests of
                            [ _ ] ->
                                []

                            _ ->
                                [ admin.checkModel 100 (\_ -> Err "Expected emoji to be assigned to text input") ]
                    )
                ]
            )
        ]
    , startTest
        "Message length limit and counter"
        startTime
        normalConfig
        [ connectTwoUsersAndJoinNewGuild
            desktopWindow
            (\admin user ->
                let
                    shortText : String
                    shortText =
                        String.repeat 100 "a"

                    atThreshold : String
                    atThreshold =
                        String.repeat 1100 "b"

                    atLimit : String
                    atLimit =
                        String.repeat 2000 "c"

                    overLimit : String
                    overLimit =
                        String.repeat 2001 "d"
                in
                [ focusEvent admin 100 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                , admin.click 100 (Dom.id "channel_textinput")

                -- Below the counter threshold: no counter is rendered.
                , admin.input 100 (Dom.id "channel_textinput") shortText
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "/2000" ])

                -- Hitting the threshold shows the counter.
                , admin.input 100 (Dom.id "channel_textinput") atThreshold
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "900/2000" ])

                -- Going over the limit still shows the counter, and Enter refuses to send.
                , admin.input 100 (Dom.id "channel_textinput") overLimit
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "-1/2000" ])
                , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                , admin.click 100 (Dom.id "messageMenu_channelInput_sendMessage")
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_message_1" ])

                -- Exactly 2000 chars is allowed and Enter sends.
                , admin.input 100 (Dom.id "channel_textinput") atLimit
                , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_message_1" ])

                -- Editing the message over the limit is blocked too.
                , admin.custom
                    100
                    (Dom.id "guild_message_1")
                    "contextmenu"
                    (Json.Encode.object
                        [ ( "clientX", Json.Encode.float 50 )
                        , ( "clientY", Json.Encode.float 150 )
                        ]
                    )
                , admin.click 2000 (Dom.id "messageMenu_editMessage")
                , admin.input 200 (Dom.id "editMessageTextInput") overLimit
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "-1/2000" ])
                , admin.keyDown 100 (Dom.id "editMessageTextInput") "Enter" []

                -- Enter with over-limit text leaves the edit dialog open (counter still shown).
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "-1/2000" ])

                -- A valid edit within the limit still works.
                , admin.input 200 (Dom.id "editMessageTextInput") "Short edit"
                , admin.keyDown 100 (Dom.id "editMessageTextInput") "Enter" []
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Short edit" ])
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Short edit" ])
                , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_message_2" ])
                , user.sendToBackend
                    100
                    (LocalModelChangeRequest (ChangeId 1)
                        (Local_SendMessage
                            (Time.millisToPosix 0)
                            (GuildOrDmId_Guild (Id.fromInt 1) (Id.fromInt 0))
                            (NonemptyString 'm' (String.repeat RichText.maxLength "m"))
                            (NoThreadWithMaybeMessage Nothing)
                            SeqDict.empty
                        )
                    )
                , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_message_2" ])
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_message_2" ])
                ]
            )
        ]
    , startTest
        "Message length limit and counter mobile"
        startTime
        normalConfig
        [ connectTwoUsersAndJoinNewGuild
            mobileWindow
            (\admin user ->
                let
                    shortText : String
                    shortText =
                        String.repeat 100 "a"

                    atThreshold : String
                    atThreshold =
                        String.repeat 1100 "b"

                    atLimit : String
                    atLimit =
                        String.repeat 2000 "c"

                    overLimit : String
                    overLimit =
                        String.repeat 2001 "d"
                in
                [ focusEvent admin 100 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                , admin.click 100 (Dom.id "channel_textinput")

                -- Below the counter threshold: no counter is rendered.
                , admin.input 100 (Dom.id "channel_textinput") shortText
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "/2000" ])

                -- Hitting the threshold shows the counter.
                , admin.input 100 (Dom.id "channel_textinput") atThreshold
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "900/2000" ])

                -- Going over the limit still shows the counter, and Enter refuses to send.
                , admin.input 100 (Dom.id "channel_textinput") overLimit
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "-1/2000" ])
                , admin.click 100 (Dom.id "messageMenu_channelInput_sendMessage")
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_message_1" ])

                -- Exactly 2000 chars is allowed and Enter sends.
                , admin.input 100 (Dom.id "channel_textinput") atLimit
                , admin.click 100 (Dom.id "messageMenu_channelInput_sendMessage")
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_message_1" ])

                -- Editing the message over the limit is blocked too.
                , admin.custom
                    100
                    (Dom.id "guild_message_1")
                    "contextmenu"
                    (Json.Encode.object
                        [ ( "clientX", Json.Encode.float 50 )
                        , ( "clientY", Json.Encode.float 150 )
                        ]
                    )
                , admin.click 2000 (Dom.id "messageMenu_editMessage")
                , admin.input 200 (Dom.id "editMessageTextInput") overLimit
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "-1/2000" ])
                , admin.click 100 (Dom.id "messageMenu_editMobile_sendMessage")

                -- Enter with over-limit text leaves the edit dialog open (counter still shown).
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "-1/2000" ])

                -- A valid edit within the limit still works.
                , admin.input 200 (Dom.id "editMessageTextInput") "Short edit"
                , admin.click 100 (Dom.id "messageMenu_editMobile_sendMessage")
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Short edit" ])
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Short edit" ])
                , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_message_2" ])
                ]
            )
        ]
    , T.testGroup "Discord" (discordTests normalConfig discordOp0Ready discordOp0ReadySupplemental)
    , startTest
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
    , startTest
        "spoilers"
        startTime
        normalConfig
        [ connectTwoUsersAndJoinNewGuild
            desktopWindow
            (\admin user ->
                [ writeMessage admin 100 "This message is ||very|| ||secret||"
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
                , writeMessage admin 100 "Another ||*super*|| *||secret||* message"
                , clickSpoiler user (Dom.id "spoiler_1_0")
                , clickSpoiler user (Dom.id "spoiler_1_1")
                , clickSpoiler user (Dom.id "spoiler_2_1")
                , clickSpoiler user (Dom.id "spoiler_2_0")
                , createThread admin (Id.fromInt 2)
                , clickSpoiler admin (Dom.id "spoiler_2_0")
                , clickSpoiler admin (Dom.id "spoiler_2_1")
                , writeMessage admin 100 "||*super*|| ||duper|| *||secret||* text"
                , user.click 100 (Dom.id "guild_threadStarterIndicator_2")
                , clickSpoiler admin (Dom.id "threadSpoiler_0_0")
                , clickSpoiler admin (Dom.id "threadSpoiler_0_2")
                ]
            )
        ]
    , startTest
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
    , startTest
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
    , startTest
        "Change notification level"
        startTime
        normalConfig
        [ connectTwoUsersAndJoinNewGuild
            desktopWindow
            (\admin user ->
                [ user.click 100 (Dom.id "guild_inviteLinkCreatorRoute")
                , user.keyUp 100 (Dom.id "guild_notificationLevel") "ArrowDown" []
                , writeMessage admin 100 "Test"
                , checkNotification "Test"
                , writeMessage admin 100 "Test 2"
                , user.click 100 (Dom.id "guild_openChannel_0")
                , writeMessage user 100 "I shouldn't get notified"
                , checkNoNotification "I shouldn't get notified"
                ]
            )
        ]

    --, startTest
    --    "Remove direct mention when viewed on another session"
    --    startTime
    --    normalConfig
    --    [ connectTwoUsersAndJoinNewGuild
    --       desktopWindow (\admin user ->
    --            [ user.click 100 (Dom.id "guildIcon_showFriends")
    --            , writeMessage admin 100 "@Stevie Steve"
    --            , writeMessage admin 100 "@Stevie Steve"
    --            , writeMessage admin 100 "@Stevie Steve"
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
    , startTest
        "Check notification icons appear"
        startTime
        normalConfig
        [ connectTwoUsersAndJoinNewGuild
            desktopWindow
            (\admin user ->
                [ user.click 100 (Dom.id "guildIcon_showFriends")
                , admin.click 100 (Dom.id "guild_newChannel")
                , admin.input 100 (Dom.id "newChannelName") "Second-channel-goes-here"
                , admin.click 100 (Dom.id "guild_createChannel")
                , writeMessage admin 100 "First message"
                , writeMessage admin 100 "Next message"
                , writeMessage admin 100 "Third message"
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.style "aria-label" "3" ])
                , user.click 100 (Dom.id "guild_openGuild_1")
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.style "aria-label" "3" ])
                , writeMessage admin 100 "@Stevie Steve Hello!"
                , writeMessage admin 100 "@Stevie Steve Hello again!"
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.style "aria-label" "2" ])
                , T.connectFrontend
                    100
                    sessionId1
                    (Route.encode Route.HomePageRoute)
                    desktopWindow
                    (\userReload ->
                        [ userReload.portEvent 10 "user_agent_from_js" (Json.Encode.string firefoxDesktop)
                        , userReload.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.style "aria-label" "2" ])
                        ]
                    )
                ]
            )
        ]
    , startTest
        "Guild icon notification is shown"
        startTime
        normalConfig
        [ connectTwoUsersAndJoinNewGuild
            desktopWindow
            (\admin user ->
                [ user.click 100 (Dom.id "guildIcon_showFriends")
                , writeMessage admin 100 "See if notification appears next to guild icon"
                , user.snapshotView 100 { name = "Guild icon new message notification" }
                , T.connectFrontend
                    100
                    sessionId1
                    (Route.encode Route.HomePageRoute)
                    desktopWindow
                    (\_ ->
                        [ user.snapshotView 100 { name = "Guild icon new message notification on reload" } ]
                    )
                , writeMessage admin 100 "@Stevie Steve now you should see a red icon"
                , user.snapshotView 100 { name = "Guild icon new mention notification" }
                ]
            )
        ]
    , startTest
        "No messages missing even in long chat history"
        startTime
        normalConfig
        [ connectTwoUsersAndJoinNewGuild
            desktopWindow
            (\_ user ->
                [ List.range 0 (VisibleMessages.pageSize * 2)
                    |> List.map (\index -> writeMessage user 1000 ("Message " ++ String.fromInt (index + 1)))
                    |> T.group
                , T.connectFrontend
                    100
                    sessionId1
                    (Route.encode Route.HomePageRoute)
                    desktopWindow
                    (\userReload ->
                        [ userReload.portEvent 10 "user_agent_from_js" (Json.Encode.string firefoxDesktop)
                        , userReload.click 100 (Dom.id "guild_openGuild_1")
                        , writeMessage userReload 100 "Another message"
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
    , startTest
        "Notifications"
        startTime
        normalConfig
        [ connectTwoUsersAndJoinNewGuild
            desktopWindow
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
                , writeMessage admin 100 "Here's a DM to you"
                , user.click 100 (Dom.id "guildsColumn_openDm_0")
                , writeMessage user 100 "Here's a reply!"
                , writeMessage user 100 "And another reply"
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
    , startTest
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
    , startTest "Logins are rate limited"
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
                case List.filterMap (isLogErrorEmail adminEmail) data.httpRequests of
                    [ "LoginsRateLimited" ] ->
                        Ok ()

                    _ ->
                        Err "Expected to only see LoginsRateLimited as an error email"
            )
        ]
    , startTest "Test login"
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
    , startTest
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
                        , tabB.portEvent 8 "load_user_settings_from_js" (Json.Encode.string "")
                        , handleLogin "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0" adminEmail tabB
                        , tabA.click 1747 (Dom.id "guild_openGuild_0")
                        , writeMessage tabA 100 "Test"
                        , tabB.click 111 (Dom.id "guild_openGuild_0")
                        , focusEvent tabB 25 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                        , tabA.mouseEnter 991 (Dom.id "guild_message_0") ( 620, 54 ) []
                        , focusEvent tabA 921 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                        , focusEvent tabA 4 Nothing Nothing
                        , focusEvent tabB 17 Nothing Nothing
                        , tabA.click 28 (Dom.id "miniView_reply")
                        , focusEvent tabA 8 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                        , tabA.mouseLeave 375 (Dom.id "guild_message_0") ( 1286, 57 ) []
                        , tabA.click 457 (Dom.id "channel_textinput")
                        , tabA.input 781 (Dom.id "channel_textinput") "Test2"
                        , focusEvent tabA 4 Nothing Nothing
                        , tabA.click 78 (Dom.id "messageMenu_channelInput_sendMessage")
                        , T.collapsableGroup
                            "Add emoji to guild channel message"
                            [ tabA.mouseEnter 1 (Dom.id "guild_message_0") ( 1036, 55 ) []
                            , tabA.click 1205 (Dom.id "miniView_showReactionEmojiSelector")
                            , tabA.mouseLeave 633 (Dom.id "guild_message_0") ( 690, -1 ) []
                            , tabA.click 991 (Dom.id "guild_emojiSelector_131")
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
                        , tabA.click 991 (Dom.id "guild_emojiSelector_131")
                        , tabB.checkView 50 (Test.Html.Query.has [ Test.Html.Selector.exactText "😀" ])
                        , tabA.mouseEnter 348 (Dom.id "guild_message_0") ( 66, 13 ) []
                        , tabA.click 548 (Dom.id "guild_removeReactionEmoji_0")
                        , tabB.checkView 50 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "😀" ])
                        , tabA.mouseLeave 410 (Dom.id "guild_message_0") ( 148, 63 ) []
                        , tabA.click 457 (Dom.id "channel_textinput")
                        , tabA.input 781 (Dom.id "channel_textinput") "Test3"
                        , focusEvent tabA 2357 Nothing Nothing
                        , tabA.click 78 (Dom.id "messageMenu_channelInput_sendMessage")
                        , tabB.click 100 (Dom.id "guild_viewThread_0_0")
                        , tabA.mouseEnter 1 (Dom.id "thread_message_0") ( 1036, 55 ) []
                        , tabA.click 1205 (Dom.id "miniView_showReactionEmojiSelector")
                        , tabA.mouseLeave 633 (Dom.id "thread_message_0") ( 690, -1 ) []
                        , tabA.click 100 (Dom.id "emoji_category_People & Body")
                        , tabA.click 991 (Dom.id "guild_emojiSelector_351")
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
    , startTest
        "Opening non-existent guild shouldn't show \"Unable to reach the server.\" warning"
        (Time.millisToPosix 1757158297558)
        normalConfig
        [ T.connectFrontend
            0
            (Lamdera.sessionIdFromString "207950c04b8f7b594cdeedebc2a8029b82943b0a")
            "/g/1/c/0"
            { width = 1615, height = 820 }
            (\tabA ->
                [ tabA.portEvent 10 "check_notification_permission_from_js" (Json.Encode.string "granted")
                , tabA.portEvent 1 "check_pwa_status_from_js" (stringToJson "false")
                , tabA.portEvent 990 "load_user_settings_from_js" (Json.Encode.string "")
                , handleLogin "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0" adminEmail tabA
                , tabA.click 17660 (Dom.id "guild_openGuild_0")
                , focusEvent tabA 17 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                , focusEvent tabA 3994 Nothing Nothing
                , tabA.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Unable to reach the server." ])
                ]
            )
        ]
    , startTest
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
            desktopWindow
            (\admin user ->
                [ writeMessage admin 100 "Hello export test!"
                , user.click 100 (Dom.id "guild_openDm_0")
                , writeMessage user 100 "Hello!"
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
    , sendMessageRateLimitTest normalConfig
    , startTest
        "Scheduled backend export uploads bytes"
        startTime
        (T.Config
            Frontend.app_
            Backend.app_
            (handleNormalHttpRequests (\_ -> Nothing))
            handlePortToJs
            (\requestData ->
                case backupRequests requestData.data of
                    [ backupA, backupB ] ->
                        let
                            oldestBackup =
                                if Time.posixToMillis backupA.sentAt < Time.posixToMillis backupB.sentAt then
                                    backupA

                                else
                                    backupB
                        in
                        case oldestBackup.body of
                            T.BytesBody mimeType bytes ->
                                UploadFile
                                    (T.uploadBytesFile "backup.bin" mimeType bytes startTime)

                            _ ->
                                UnhandledFileUpload

                    _ ->
                        UnhandledFileUpload
            )
            handleMultiFileUpload
            domain
        )
        [ connectTwoUsersAndJoinNewGuild
            desktopWindow
            (\admin user ->
                [ writeMessage admin 100 "Hello export test!"
                , user.click 100 (Dom.id "guild_openDm_0")
                , writeMessage user 100 "Hello!"
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
                        [ T.checkState
                            (Duration.hours 5 |> Duration.inMilliseconds)
                            (\data ->
                                case backupRequests data of
                                    [ _ ] ->
                                        Ok ()

                                    [] ->
                                        Err "Expected one upload HTTP request for scheduled export"

                                    _ ->
                                        Err "Expected exactly one upload HTTP request for scheduled export"
                            )
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
                        , T.checkState
                            (Duration.hours 4 |> Duration.inMilliseconds)
                            (\data ->
                                case backupRequests data of
                                    [ _, _ ] ->
                                        Ok ()

                                    [] ->
                                        Err "Expected two upload HTTP request for scheduled export"

                                    _ ->
                                        Err "Expected exactly one upload HTTP request for scheduled export"
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


backupRequests : T.Data FrontendModel BackendModel -> List HttpRequest
backupRequests data =
    List.filter
        (\request ->
            String.startsWith "http://localhost:3000/file/internal/upload-backup/backend-export-" request.url
                && (request.method == "POST")
                && (request.requestedBy == RequestedByBackend)
        )
        data.httpRequests


sendMessageRateLimitTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
sendMessageRateLimitTest config =
    startTest
        "SendMessage rate limiting"
        startTime
        config
        [ connectTwoUsersAndJoinNewGuild
            desktopWindow
            (\admin user ->
                let
                    guildId : Id GuildId
                    guildId =
                        Id.fromInt 1

                    channelId : Id ChannelId
                    channelId =
                        Id.fromInt 0

                    sendMessage :
                        T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
                        -> Float
                        -> Int
                        -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
                    sendMessage client delayInMs changeIndex =
                        client.sendToBackend
                            delayInMs
                            (LocalModelChangeRequest (ChangeId changeIndex)
                                (Local_SendMessage
                                    (Time.millisToPosix 0)
                                    (GuildOrDmId_Guild guildId channelId)
                                    (NonemptyString 'm' ("sg " ++ String.fromInt changeIndex))
                                    (NoThreadWithMaybeMessage Nothing)
                                    SeqDict.empty
                                )
                            )

                    getMessageCount : BackendModel -> Int
                    getMessageCount backend =
                        case SeqDict.get guildId backend.guilds of
                            Just guild ->
                                case SeqDict.get channelId guild.channels of
                                    Just channel ->
                                        Array.length channel.messages

                                    Nothing ->
                                        -1

                            Nothing ->
                                -1

                    checkMessageCount : String -> Int -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
                    checkMessageCount label expected =
                        T.checkBackend
                            100
                            (\backend ->
                                let
                                    actual =
                                        getMessageCount backend
                                in
                                if actual == expected then
                                    Ok ()

                                else
                                    Err (label ++ ": Expected " ++ String.fromInt expected ++ " messages but got " ++ String.fromInt actual)
                            )
                in
                [ T.andThen
                    100
                    (\dataBefore ->
                        let
                            initialCount =
                                getMessageCount dataBefore.backend
                        in
                        [ List.range 0 (RateLimit.shortWindowMaxMessages - 1)
                            |> List.map (sendMessage admin 0)
                            |> T.collapsableGroup "Send messages up to rate limit"
                        , List.range RateLimit.shortWindowMaxMessages (RateLimit.shortWindowMaxMessages + 4)
                            |> List.map (sendMessage admin 0)
                            |> T.collapsableGroup "Send messages exceeding rate limit"
                        , checkMessageCount "After rate limit" (initialCount + RateLimit.shortWindowMaxMessages)
                        , T.collapsableGroup
                            "User2 can still send while admin is rate limited"
                            [ sendMessage user 0 200 ]
                        , checkMessageCount "User2 not rate limited" (initialCount + RateLimit.shortWindowMaxMessages + 1)
                        , T.collapsableGroup
                            "After rate limit window, sending works again"
                            [ sendMessage admin (Duration.inMilliseconds RateLimit.shortWindowDuration + 1) 100 ]
                        , checkMessageCount "After window reset" (initialCount + RateLimit.shortWindowMaxMessages + 2)
                        , List.range 101 (RateLimit.longWindowMaxMessages + 101)
                            |> List.map (sendMessage admin 2000)
                            |> T.collapsableGroup "Send messages exceeding rate limit"
                        , checkMessageCount "After long rate limit" (initialCount + RateLimit.longWindowMaxMessages + 1)
                        , sendMessage admin (Duration.inMilliseconds RateLimit.longWindowDuration) 1000
                        , checkMessageCount "After long rate limit has expired" (initialCount + RateLimit.longWindowMaxMessages + 2)
                        , T.checkBackend
                            100
                            (\backend ->
                                let
                                    actual =
                                        SeqDict.foldl (\_ array count -> Array.length array + count) 0 backend.sendMessageRateLimits
                                in
                                if actual == 2 then
                                    Ok ()

                                else
                                    Err ("Old rate limit logs aren't being filtered. Expected 2 but got " ++ String.fromInt actual)
                            )
                        ]
                    )
                ]
            )
        ]


checkNoErrorLogs : T.Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
checkNoErrorLogs =
    T.checkState
        100
        (\data ->
            case List.filterMap (isLogErrorEmail Backend.adminUser.email) data.httpRequests of
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


attackerTriesToLeakSensitiveData :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> String
    -> String
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
attackerTriesToLeakSensitiveData config discordOpReady discordOpSupplemental =
    T.start
        "Attacker tries to leak/modify sensitive data"
        startTime
        config
        [ linkDiscordAndLogin
            sessionId0
            "AT"
            adminEmail
            False
            discordOpReady
            discordOpSupplemental
            (\admin ->
                [ inviteUser
                    admin
                    (\user ->
                        [ writeMessage user 100 "sensitive guild message"
                        , admin.click 100 (Dom.id "guild_openChannel_0")
                        , writeMessage admin 100 "sensitive guild message 2"
                        , user.click 1000 (Dom.id "guild_openDm_0")
                        , writeMessage user 100 "sensitive DM message"
                        , T.connectFrontend
                            100
                            sessionIdAttacker
                            "/"
                            desktopWindow
                            (\attacker ->
                                [ handleLogin chromeDesktop attackerEmail attacker
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
                                            allAttackerLocalChanges
                                            |> T.collapsableGroup "attacks"
                                        , List.map (attacker.sendToBackend 100) allAttackerToBackendChanges
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
                                                            ++ (if before.backend.discordGuilds == after.backend.discordGuilds then
                                                                    []

                                                                else
                                                                    [ "Discord guild data was modified by attacker" ]
                                                               )
                                                            ++ (if before.backend.discordDmChannels == after.backend.discordDmChannels then
                                                                    []

                                                                else
                                                                    [ "Discord DM data was modified by attacker" ]
                                                               )
                                                            ++ (if before.backend.discordUsers == after.backend.discordUsers then
                                                                    []

                                                                else
                                                                    [ "Discord user data was modified by attacker" ]
                                                               )
                                                            ++ (if before.backend.pendingDiscordCreateMessages == after.backend.pendingDiscordCreateMessages then
                                                                    []

                                                                else
                                                                    [ "Pending Discord guild messages modified by attacker" ]
                                                               )
                                                            ++ (if before.backend.pendingDiscordCreateDmMessages == after.backend.pendingDiscordCreateDmMessages then
                                                                    []

                                                                else
                                                                    [ "Pending Discord DM messages modified by attacker" ]
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

                Local_NewChannel _ _ _ ->
                    True

                Local_EditChannel _ _ _ ->
                    True

                Local_DeleteChannel _ _ ->
                    True

                Local_NewInviteLink _ _ _ ->
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

                Local_RegisterPushSubscription _ ->
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

                        Types.Server_DiscordGuildMemberJoined _ _ _ _ _ ->
                            True

                        Types.Server_LinkedDiscordUserStickersLoaded _ ->
                            True

                        Types.Server_LinkedDiscordUserCustomEmojisLoaded _ ->
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


allAttackerToBackendChanges : List ToBackend
allAttackerToBackendChanges =
    [ CheckLoginRequest InitialLoadRequested_None
    , LoginWithTokenRequest InitialLoadRequested_None 0 UserAgent.init
    , LoginWithTwoFactorRequest InitialLoadRequested_None 0 UserAgent.init
    , GetLoginTokenRequest (Unsafe.emailAddress "attacker@example.com" |> Untrusted.untrust)
    , AdminToBackend (Pages.Admin.ExportBackendRequest Pages.Admin.ExportAll)
    , LocalModelChangeRequest (ChangeId 0) Local_Invalid
    , TwoFactorToBackend TwoFactorAuthentication.EnableTwoFactorAuthenticationRequest
    , JoinGuildByInviteRequest (Id.fromInt 0) (SecretId "fake-invite-link")
    , FinishUserCreationRequest InitialLoadRequested_None (Unsafe.personName "hacked") UserAgent.init
    , AiChatToBackend (AiChat.AiMessageRequestSimple (AiModelName "model") (AiChat.RespondId 0) "hacked")
    , ReloadDataRequest InitialLoadRequested_None
    , LinkSlackOAuthCode (Slack.OAuthCode "fake-code") (SessionIdHash "fake-hash")
    , LinkDiscordRequest { discordUserAuth | token = "attacker-token" }
    , ProfilePictureEditorToBackend (ImageEditor.ChangeUserAvatarRequest (FileStatus.FileHash "fake-hash"))
    , AdminDataRequest Nothing
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

        emoji : EmojiOrCustomEmoji
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
    , Local_EditChannel legitGuildId channelId (Unsafe.channelName "hacked")
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
    , Local_NewChannel messageTime legitGuildId (Unsafe.channelName "hacked")
    , Local_NewGuild messageTime (Unsafe.guildName "hacked") EmptyPlaceholder
    , Local_NewInviteLink messageTime legitGuildId EmptyPlaceholder
    , Local_RegisterPushSubscription { endpoint = domain, auth = "auth", p256dh = "p256dh" }
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
    ]


currentDiscordUserId : Discord.Id Discord.UserId
currentDiscordUserId =
    Unsafe.uint64 "184437096813953035" |> Discord.idFromUInt64


botTestGuild : Discord.Id Discord.GuildId
botTestGuild =
    Unsafe.uint64 "705745250815311942" |> Discord.idFromUInt64


botTestGuild_ChannelA : Discord.Id Discord.ChannelId
botTestGuild_ChannelA =
    Unsafe.uint64 "1072828564317159465" |> Discord.idFromUInt64


discordTests :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> String
    -> String
    -> List (T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
discordTests normalConfig discordOp0Ready discordOp0ReadySupplemental =
    [ startTest
        "Got rich text embed"
        startTime
        normalConfig
        [ linkDiscordAndLogin
            sessionId0
            (PersonName.toString Backend.adminUser.name)
            adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ andThenWebsocket
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":173,"op":0,"d":{"webhook_id":"1374332266083254363","type":0,"tts":false,"timestamp":"2026-04-16T01:36:56.515000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"id":"1494149566100930611","flags":0,"embeds":[{"type":"rich","title":"[compiler] Branch distribute was force-pushed to `c7b3d5e`","id":"1494149566100930612","description":"[Compare changes](https://github.com/lamdera/compiler/compare/01daaf8875d1...c7b3d5e6f412)","content_scan_version":4,"color":16525609,"author":{"url":"https://github.com/supermario","proxy_icon_url":"https://images-ext-1.discordapp.net/external/EOjvf3Ly7SSCVe7o-8EBJBz6V_MUyiX7n4TkBiIkZnI/%3Fv%3D4/https/avatars.githubusercontent.com/u/102781","name":"supermario","icon_url":"https://avatars.githubusercontent.com/u/102781?v=4"}}],"edited_timestamp":null,"content":"","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"GitHub","id":"1374332266083254363","global_name":null,"discriminator":"0000","bot":true,"avatar":"e57fd67dc7ca0cc840a0e87a82281bc5"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , admin.checkView
                            100
                            (\html ->
                                Test.Html.Query.find [ Test.Html.Selector.id "spoiler_0_0" ] html
                                    |> Test.Html.Query.hasNot [ Test.Html.Selector.tag "img" ]
                            )
                        ]
                    )
                ]
            )
        ]
    , startTest
        "Got spoilered image"
        startTime
        normalConfig
        [ linkDiscordAndLogin
            sessionId0
            (PersonName.toString Backend.adminUser.name)
            adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ andThenWebsocket
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":3,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-12T13:14:33.237000+00:00","pinned":false,"nonce":"1492875573255471104","mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":[],"premium_since":null,"pending":false,"nick":null,"mute":false,"joined_at":"2020-05-01T11:39:39.915000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":"1492875574455042168","flags":0,"embeds":[],"edited_timestamp":null,"content":"","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"at0232","public_flags":0,"primary_guild":null,"id":"161098476632014848","global_name":"AT","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"3d7b1aa7b5149fe06971b6dedf682d82"},"attachments":[{"width":80,"url":"https://cdn.discordapp.com/attachments/1072828564317159465/1492875574174154943/SPOILER_1122943867721875456.png?ex=69dcec39&is=69db9ab9&hm=992b357861cbb393bf8fdfac2690f576b6283968400d3cd18dd2d9f7e117c65b&","size":492063,"proxy_url":"https://media.discordapp.net/attachments/1072828564317159465/1492875574174154943/SPOILER_1122943867721875456.png?ex=69dcec39&is=69db9ab9&hm=992b357861cbb393bf8fdfac2690f576b6283968400d3cd18dd2d9f7e117c65b&","placeholder_version":1,"placeholder":"ZCmGHQYsRFqRmof6NoZvZ/lnBEaEhnJkWA==","original_content_type":"image/png","id":"1492875574174154943","height":80,"flags":40,"filename":"SPOILER_1122943867721875456.png","content_type":"image/png","content_scan_version":4}],"guild_id":"705745250815311942"}}"""
                        , admin.checkView
                            100
                            (\html ->
                                Test.Html.Query.find [ Test.Html.Selector.id "spoiler_0_0" ] html
                                    |> Test.Html.Query.hasNot [ Test.Html.Selector.tag "img" ]
                            )
                        ]
                    )
                ]
            )
        ]
    , startTest
        "Message created by unlinked user containing only embed"
        startTime
        normalConfig
        [ linkDiscordAndLogin
            sessionId0
            (PersonName.toString Backend.adminUser.name)
            adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ andThenWebsocket
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":476,"op":0,"d":{"webhook_id":"1374332266083254363","type":0,"tts":false,"timestamp":"2026-03-31T20:15:05.862000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"id":"1488632753368072280","flags":0,"embeds":[{"url":"https://github.com/lamdera/compiler/pull/92","type":"rich","title":"[lamdera/compiler] Pull request opened: #92   Allow configuring <html lang> via html-lang file","id":"1488632753368072281","description":"Read an optional html-lang file from the project root to set the lang attribute on the generated  tag.  If the file contains e.g. \\"fr\\", the output becomes .  If absent or empty, the tag is plain  as before.  Fixes #84.","content_scan_version":4,"color":38912,"author":{"url":"https://github.com/MavenRain","proxy_icon_url":"https://images-ext-1.discordapp.net/external/z5iI09eMZ6hW8pY8xflOmWevOiHuXRD-pljR_thC38Q/%3Fv%3D4/https/avatars.githubusercontent.com/u/7246681","name":"MavenRain","icon_url":"https://avatars.githubusercontent.com/u/7246681?v=4"}}],"edited_timestamp":null,"content":"","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"GitHub","id":"1374332266083254363","global_name":null,"discriminator":"0000","bot":true,"avatar":"e57fd67dc7ca0cc840a0e87a82281bc5"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Title for https://github.com/lamdera/compiler/pull/92" ])
                        ]
                    )
                ]
            )
        ]
    , startTest
        "Discord friend label shows typing indicator"
        startTime
        normalConfig
        [ linkDiscordAndLogin
            sessionId0
            (PersonName.toString Backend.adminUser.name)
            adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ andThenWebsocket
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guildIcon_showFriends")
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.exactText "Typing..." ]
                            )
                        , T.websocketSendString 100 connection "{\"t\":\"TYPING_START\",\"s\":3,\"op\":0,\"d\":{\"channel_id\":\"185574444641550336\",\"user_id\":\"161098476632014848\",\"timestamp\":1}}"
                        , admin.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.exactText "Typing..." ]
                            )
                        ]
                    )
                ]
            )
        ]
    , startTest
        "Message created by linked user containing url"
        startTime
        normalConfig
        [ linkDiscordAndLogin
            sessionId0
            (PersonName.toString Backend.adminUser.name)
            adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ andThenWebsocket
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , writeMessage admin 100 "https://www.youtube.com/watch?v=zAFDQH19pV4"
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":3,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-01T10:04:25.211000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":[],"premium_since":null,"pending":false,"nick":null,"mute":false,"joined_at":"2025-10-11T19:44:51.312000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":"1488841459204489398","flags":0,"embeds":[],"edited_timestamp":null,"content":"https://www.youtube.com/watch?v=zAFDQH19pV4","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"at28727","public_flags":0,"primary_guild":null,"id":"184437096813953035","global_name":"AT2","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"7c40cb63ea11096169c5a4dcb5825a3d"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , T.websocketSendString 1000 connection """{"t":"MESSAGE_UPDATE","s":4,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-01T10:04:25.211000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":[],"premium_since":null,"pending":false,"nick":null,"mute":false,"joined_at":"2025-10-11T19:44:51.312000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":"1488841459204489398","flags":0,"embeds":[{"video":{"width":720,"url":"https://www.youtube.com/embed/zAFDQH19pV4","placeholder_version":1,"placeholder":"lDgKDIQHiJZyiniCe3ingHsKqA==","height":720,"flags":0},"url":"https://www.youtube.com/watch?v=zAFDQH19pV4","type":"video","title":"Spiral (jackLNDN Remix)","thumbnail":{"width":1280,"url":"https://i.ytimg.com/vi/zAFDQH19pV4/maxresdefault.jpg","proxy_url":"https://images-ext-1.discordapp.net/external/o1Bl70OhMLyAuYI0AvggMLdse0h4epFkr-Nd4Ru9L3I/https/i.ytimg.com/vi/zAFDQH19pV4/maxresdefault.jpg","placeholder_version":1,"placeholder":"lDgKDIQHiJZyiniCe3ingHsKqA==","height":720,"flags":0,"content_type":"image/jpeg"},"provider":{"url":"https://www.youtube.com","name":"YouTube"},"id":"1488841460739739829","description":"Provided to YouTube by Label Worx Limited\\n\\nSpiral (jackLNDN Remix) · Lena Leon · jackLNDN · jackLNDN\\n\\nSpiral (Deluxe Edition)\\n\\n℗ Big Proof Publishing, Danny Danger Publishing, Ultra Empire Music (BMI) obo itself and LRL Music, Whizz Kid II Publishing GmbH, Hooks & Crooks BMG Rights Management GmbH\\n\\nReleased on: 2023-02-10\\n\\nProducer: jackLND...","color":16711680,"author":{"url":"https://www.youtube.com/channel/UCQ8EctjrppQcwBA3lEIlk4w","name":"Lena Leon - Topic"}}],"edited_timestamp":null,"content":"https://www.youtube.com/watch?v=zAFDQH19pV4","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"at28727","public_flags":0,"primary_guild":null,"id":"184437096813953035","global_name":"AT2","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"7c40cb63ea11096169c5a4dcb5825a3d"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Title for https://www.youtube.com/watch?v=zAFDQH19pV4" ])
                        ]
                    )
                ]
            )
        ]
    , startTest
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
    , startTest "Forwarded message"
        startTime
        normalConfig
        [ linkDiscordAndLogin
            sessionId0
            (PersonName.toString Backend.adminUser.name)
            adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ andThenWebsocket
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":3293,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-17T16:14:03.131000+00:00","pinned":false,"nonce":"1494732679017398272","message_snapshots":[{"message":{"type":0,"timestamp":"2026-04-17T11:22:04.856000+00:00","mentions":[],"flags":0,"embeds":[],"edited_timestamp":null,"content":"","components":[],"attachments":[{"width":2160,"url":"https://cdn.discordapp.com/attachments/123/321/IMG_1234.jpg?ex=123&is=321&hm=123&","size":517431,"proxy_url":"https://media.discordapp.net/attachments/123/321/1234.jpg?ex=123&is=321&hm=123&","placeholder_version":1,"placeholder":"WlkKDgSql6d2d3d4d4B4gZqYrHCJCGc=","id":"1494732685631946782","height":2461,"filename":"IMG_7203.jpg","content_type":"image/jpeg","content_scan_version":4}]}}],"message_reference":{"type":1,"message_id":"1494659209021751327","channel_id":"1472236476401057854"},"mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":["476506921260810240","734405273103499264","743849378363605082","840010386958581770","776291214478802964","840041852852895765","1030137708531687514"],"premium_since":null,"pending":false,"nick":"cute technology","mute":false,"joined_at":"2018-08-07T17:00:17.616000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":"1494732685992530114","flags":16384,"embeds":[],"edited_timestamp":null,"content":"","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"capysuit","public_flags":0,"primary_guild":null,"id":"339560235050205185","global_name":"gio","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"7d2709668c67727f98ba40ff62611e78"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , admin.checkView 1000 (Test.Html.Query.hasNot [ Test.Html.Selector.text "empty" ])
                        ]
                    )
                ]
            )
        ]
    , startTest
        "Message with sticker"
        startTime
        normalConfig
        [ linkDiscordAndLogin
            sessionId0
            (PersonName.toString Backend.adminUser.name)
            adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ andThenWebsocket
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , admin.click 100 (Dom.id "messageMenu_channelInput_openEmojiSelector")
                        , admin.click 100 (Dom.id "emoji_category_Stickers")
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.tag "lottie-player" ])
                        , admin.checkView
                            100
                            (\html ->
                                Test.Html.Query.findAll [ Test.Html.Selector.tag "animated-image-player" ] html
                                    |> Test.Html.Query.count (Expect.equal 2)
                            )
                        , admin.click 100 (Dom.id "elm-ui-root-id")
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_CREATE\",\"s\":4,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-04-07T23:35:37.476000+00:00\",\"sticker_items\":[{\"name\":\"sticker1\",\"id\":\"1490687750288965813\",\"format_type\":2}],\"pinned\":false,\"nonce\":\"1491219931943927808\",\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1491219932673740970\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Message with text and sticker!\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.text "Sticker failed to load"
                                , Test.Html.Selector.tag "lottie-player"
                                ]
                            )
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "Message with text and sticker!" ])
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_CREATE\",\"s\":5,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-04-07T23:36:41.898000+00:00\",\"sticker_items\":[{\"name\":\"Happy\",\"id\":\"796140620111544330\",\"format_type\":3}],\"pinned\":false,\"nonce\":\"1491220202350706688\",\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1491220202879324241\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.tag "lottie-player" ])
                        ]
                    )
                ]
            )
        , T.connectFrontend
            100
            sessionId0
            (Route.encode
                (Route.DiscordGuildRoute
                    { currentDiscordUserId = currentDiscordUserId
                    , guildId = botTestGuild
                    , channelRoute =
                        Route.DiscordChannel_ChannelRoute
                            botTestGuild_ChannelA
                            (Route.NoThreadWithFriends Nothing Route.ShowMembersTab)
                    }
                )
            )
            desktopWindow
            (\admin ->
                [ admin.portEvent 10 "user_agent_from_js" (Json.Encode.string firefoxDesktop)
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.text "Sticker failed to load" ])
                , admin.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.tag "lottie-player"
                        , Test.Html.Selector.exactText "Message with text and sticker!"
                        ]
                    )
                , inviteUser
                    admin
                    (\user ->
                        [ admin.click 100 (Dom.id "guild_openChannel_0")
                        , admin.click 100 (Dom.id "messageMenu_channelInput_openEmojiSelector")
                        , admin.click 100 (Dom.id "emoji_category_Stickers")
                        , admin.click 100 (Dom.id "guild_emojiSelector_0")
                        , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.tag "animated-image-player" ])
                        , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.tag "animated-image-player" ])
                        , T.andThen
                            30
                            (\data ->
                                case
                                    List.filter
                                        (\request -> request.clientId == admin.clientId && request.portName == "exec_command_to_js")
                                        data.portRequests
                                of
                                    [ _ ] ->
                                        [ admin.update
                                            30
                                            (Types.MessageInputMsg
                                                (GuildOrDmId (GuildOrDmId_Guild (Id.fromInt 0) (Id.fromInt 0)))
                                                NoThread
                                                (MessageInput.TypedMessage (Sticker.idToString (Id.fromInt 3)))
                                            )
                                        , admin.click 100 (Dom.id "messageMenu_channelInput_sendMessage")
                                        ]

                                    _ ->
                                        [ admin.checkModel 100 (\_ -> Err "Didn't add sticker to text input") ]
                            )
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.tag "animated-image-player" ])
                        , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.tag "animated-image-player" ])
                        ]
                    )
                ]
            )
        ]
    , startTest
        "Message with new custom emoji"
        startTime
        normalConfig
        [ linkDiscordAndLogin
            sessionId0
            (PersonName.toString Backend.adminUser.name)
            adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ andThenWebsocket
                    (\connection _ ->
                        let
                            customEmojiNamed : String -> T.Data FrontendModel BackendModel -> List CustomEmoji.CustomEmojiData
                            customEmojiNamed name data =
                                SeqDict.values data.backend.customEmojis
                                    |> List.filter (\customEmoji -> CustomEmoji.emojiNameToString customEmoji.name == name)
                        in
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , T.checkState
                            100
                            (\data ->
                                if List.isEmpty (customEmojiNamed "newemoji" data) then
                                    Ok ()

                                else
                                    Err "Backend already has the new custom emoji loaded before the message was sent"
                            )
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_CREATE\",\"s\":4,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-04-29T00:00:00.000000+00:00\",\"pinned\":false,\"nonce\":\"1500000000000000000\",\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1500000000000000001\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Hello <:newemoji:888159336168300599>\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.text "Custom emoji failed to load" ])
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.text "Hello" ])
                        , T.checkState
                            100
                            (\data ->
                                case customEmojiNamed "newemoji" data of
                                    [ customEmoji ] ->
                                        case customEmoji.url of
                                            CustomEmoji.CustomEmojiInternal _ _ ->
                                                Ok ()

                                            CustomEmoji.CustomEmojiLoading ->
                                                Err "Backend loaded the new custom emoji but it is still in the loading state"

                                    [] ->
                                        Err "Backend did not load the new custom emoji from the message"

                                    _ ->
                                        Err "Backend loaded more than one custom emoji called \"newemoji\""
                            )
                        ]
                    )
                ]
            )
        ]
    , startTest
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
    , startTest
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
    , startTest
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
    , startTest
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
                                                ( "http://localhost:3000/file/internal/custom-request", Just customRequest ) ->
                                                    (customRequest.url == "https://discord.com/api/v9/channels/705745250815311942/thread-members/@me")
                                                        && (customRequest.method == "PUT")

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
    , startTest
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
                                                ( "http://localhost:3000/file/internal/custom-request", Just customRequest ) ->
                                                    (customRequest.url == "https://discord.com/api/v9/channels/1486698771915083887/thread-members/@me")
                                                        && (customRequest.method == "PUT")

                                                _ ->
                                                    False
                                        )
                                        data.httpRequests
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
    , startTest
        "Discord guild typing indicator"
        startTime
        normalConfig
        [ linkDiscordAndLogin
            sessionId0
            (PersonName.toString Backend.adminUser.name)
            adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                , andThenWebsocket
                    (\connection _ ->
                        [ admin.checkView
                            100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.exactText "at0232 is typing..." ]
                            )
                        , T.websocketSendString
                            100
                            connection
                            ("{\"t\":\"TYPING_START\",\"s\":3,\"op\":0,\"d\":{\"channel_id\":\"1072828564317159465\",\"guild_id\":\"705745250815311942\",\"user_id\":\"161098476632014848\",\"timestamp\":"
                                ++ String.fromInt (Time.posixToMillis (Duration.addTo startTime (Duration.seconds 3)))
                                ++ "}}"
                            )
                        , admin.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.exactText "at0232 is typing..." ]
                            )
                        ]
                    )
                ]
            )
        ]
    , startTest
        "Handle new sticker in guild message"
        startTime
        normalConfig
        [ linkDiscordAndLogin
            sessionId0
            (PersonName.toString Backend.adminUser.name)
            adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                , andThenWebsocket
                    (\connection _ ->
                        [ T.websocketSendString
                            100
                            connection
                            """{"t":"MESSAGE_CREATE","s":521,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-14T04:41:03.112000+00:00","sticker_items":[{"name":"Yippee","id":"1490556070756618301","format_type":1}],"pinned":false,"nonce":"1493471122245550080","mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":["1039567586788122624","1113304630558986240","910335245230944266","686309065940533259","686292987625472082","639296395513430037"],"premium_since":"2022-09-10T14:38:28.084000+00:00","pending":false,"nick":"yargle's gargle marble","mute":false,"joined_at":"2020-03-08T20:30:03.582000+00:00","flags":0,"display_name_styles":{"font_id":4,"effect_id":1,"colors":[]},"deaf":false,"communication_disabled_until":null,"banner":"0aba747031ece851b97166a093d1c509","avatar":"dc78d57d93da1b00fbf15a005821ffa5"},"id":"1493471123155714198","flags":0,"embeds":[],"edited_timestamp":null,"content":"","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"puncharoonie","public_flags":0,"primary_guild":{"tag":"BoNY","identity_guild_id":"821802567876083743","identity_enabled":true,"badge":"4ef966b9bdd3ca7155e184e893314cd6"},"id":"313112240758718464","global_name":"puncharoonie","display_name_styles":{"font_id":7,"effect_id":5,"colors":[1027403]},"discriminator":"0","collectibles":{"nameplate":{"sku_id":"1417311919429128312","palette":"berry","label":"COLLECTIBLES_NAMEPLATE_BONANZA_BERRY_BUNNY_NP_A11Y","expires_at":null,"asset":"nameplates/nameplate_bonanza/berry_bunny/"}},"clan":{"tag":"BoNY","identity_guild_id":"821802567876083743","identity_enabled":true,"badge":"4ef966b9bdd3ca7155e184e893314cd6"},"avatar_decoration_data":{"sku_id":"1354894010522800158","expires_at":null,"asset":"a_b70f0a0cecf3097eae17a8f7d8c659a8"},"avatar":"ae79bf23d7d379b2465eadc6994a2583"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , admin.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.attribute
                                    (Html.Attributes.src
                                        "http://localhost:3000/file/2/https://media.discordapp.net/stickers/1490556070756618301.png?size=480&quality=lossless"
                                    )
                                ]
                            )
                        ]
                    )
                ]
            )
        ]
    , startTest
        "Handle new sticker in DM message"
        startTime
        normalConfig
        [ linkDiscordAndLogin
            sessionId0
            (PersonName.toString Backend.adminUser.name)
            adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ admin.click 100 (Dom.id "guild_discordFriendLabel_1472236476401057854")
                , andThenWebsocket
                    (\connection _ ->
                        [ T.websocketSendString
                            100
                            connection
                            """{"t":"MESSAGE_CREATE","s":521,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-14T04:41:03.112000+00:00","sticker_items":[{"name":"Yippee","id":"1490556070756618301","format_type":1}],"pinned":false,"nonce":"1493471122245550080","mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":["1039567586788122624","1113304630558986240","910335245230944266","686309065940533259","686292987625472082","639296395513430037"],"premium_since":"2022-09-10T14:38:28.084000+00:00","pending":false,"nick":"yargle's gargle marble","mute":false,"joined_at":"2020-03-08T20:30:03.582000+00:00","flags":0,"display_name_styles":{"font_id":4,"effect_id":1,"colors":[]},"deaf":false,"communication_disabled_until":null,"banner":"0aba747031ece851b97166a093d1c509","avatar":"dc78d57d93da1b00fbf15a005821ffa5"},"id":"1493471123155714198","flags":0,"embeds":[],"edited_timestamp":null,"content":"","components":[],"channel_type":0,"channel_id":"1472236476401057854","author":{"username":"purplelite","public_flags":0,"primary_guild":{"tag":"BoNY","identity_guild_id":"821802567876083743","identity_enabled":true,"badge":"4ef966b9bdd3ca7155e184e893314cd6"},"id":"137748026084163584","global_name":"purplelite","display_name_styles":{"font_id":7,"effect_id":5,"colors":[1027403]},"discriminator":"0","collectibles":{"nameplate":{"sku_id":"1417311919429128312","palette":"berry","label":"COLLECTIBLES_NAMEPLATE_BONANZA_BERRY_BUNNY_NP_A11Y","expires_at":null,"asset":"nameplates/nameplate_bonanza/berry_bunny/"}},"clan":{"tag":"BoNY","identity_guild_id":"821802567876083743","identity_enabled":true,"badge":"4ef966b9bdd3ca7155e184e893314cd6"},"avatar_decoration_data":{"sku_id":"1354894010522800158","expires_at":null,"asset":"a_b70f0a0cecf3097eae17a8f7d8c659a8"},"avatar":"ae79bf23d7d379b2465eadc6994a2583"},"attachments":[]}}"""
                        , admin.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.attribute
                                    (Html.Attributes.src
                                        "http://localhost:3000/file/2/https://media.discordapp.net/stickers/1490556070756618301.png?size=480&quality=lossless"
                                    )
                                ]
                            )
                        ]
                    )
                ]
            )
        ]

    --, startTest
    --    "Discord guild thread typing indicator"
    --    startTime
    --    normalConfig
    --    [ linkDiscordAndLogin
    --        sessionId0
    --        (PersonName.toString Backend.adminUser.name)
    --        adminEmail
    --        False
    --        discordOp0Ready
    --        discordOp0ReadySupplemental
    --        (\admin ->
    --            [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
    --            , andThenWebsocket
    --                (\connection _ ->
    --                    [ T.websocketSendString
    --                        100
    --                        connection
    --                        "{\"t\":\"MESSAGE_CREATE\",\"s\":4,\"op\":0,\"d\":{\"type\":18,\"tts\":false,\"timestamp\":\"2026-03-26T12:10:08.752000+00:00\",\"pinned\":false,\"message_reference\":{\"type\":0,\"guild_id\":\"705745250815311942\",\"channel_id\":\"1486698771915083887\"},\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1486698771915083887\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Thread starter\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
    --                    , T.websocketSendString
    --                        100
    --                        connection
    --                        "{\"t\":\"MESSAGE_UPDATE\",\"s\":5,\"op\":0,\"d\":{\"type\":18,\"tts\":false,\"timestamp\":\"2026-03-26T12:10:08.752000+00:00\",\"pinned\":false,\"message_reference\":{\"type\":0,\"guild_id\":\"705745250815311942\",\"channel_id\":\"1486698771915083887\"},\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1486698771915083887\",\"flags\":32,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Thread starter\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
    --                    , T.websocketSendString
    --                        100
    --                        connection
    --                        "{\"t\":\"GUILD_AUDIT_LOG_ENTRY_CREATE\",\"s\":6,\"op\":0,\"d\":{\"user_id\":\"161098476632014848\",\"target_id\":\"1486698771915083887\",\"id\":\"1486698771915083888\",\"changes\":[{\"new_value\":\"Thread starter\",\"key\":\"name\"},{\"new_value\":11,\"key\":\"type\"},{\"new_value\":false,\"key\":\"archived\"},{\"new_value\":false,\"key\":\"locked\"},{\"new_value\":4320,\"key\":\"auto_archive_duration\"},{\"new_value\":0,\"key\":\"rate_limit_per_user\"},{\"new_value\":0,\"key\":\"flags\"}],\"action_type\":110,\"guild_id\":\"705745250815311942\"}}"
    --                    , T.websocketSendString
    --                        100
    --                        connection
    --                        "{\"t\":\"THREAD_MEMBERS_UPDATE\",\"s\":7,\"op\":0,\"d\":{\"member_ids_preview\":[\"161098476632014848\",\"184437096813953035\"],\"member_count\":2,\"id\":\"1486698771915083887\",\"added_members\":[{\"user_id\":\"184437096813953035\",\"presence\":{\"user\":{\"username\":\"at28727\",\"primary_guild\":null,\"id\":\"184437096813953035\",\"global_name\":\"AT2\",\"discriminator\":\"0\",\"clan\":null,\"bot\":false,\"avatar_decoration_data\":null,\"avatar\":\"7c40cb63ea11096169c5a4dcb5825a3d\"},\"status\":\"online\",\"processed_at_timestamp\":0,\"game\":null,\"client_status\":{\"web\":\"online\"},\"activities\":[]},\"muted\":false,\"mute_config\":null,\"member\":{\"user\":{\"username\":\"at28727\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"184437096813953035\",\"global_name\":\"AT2\",\"display_name_styles\":null,\"display_name\":\"AT2\",\"discriminator\":\"0\",\"collectibles\":null,\"bot\":false,\"avatar_decoration_data\":null,\"avatar\":\"7c40cb63ea11096169c5a4dcb5825a3d\"},\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2025-10-11T19:44:51.312000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"join_timestamp\":\"2026-03-26T12:10:09.250111+00:00\",\"id\":\"1486698771915083887\",\"flags\":1}],\"guild_id\":\"705745250815311942\"}}"
    --                    , T.andThen
    --                        100
    --                        (\data ->
    --                            case
    --                                List.filter
    --                                    (\request ->
    --                                        case ( request.url, decodeCustomRequest request ) of
    --                                            ( "http://localhost:3000/file/internal/custom-request", Just ( method, url ) ) ->
    --                                                (url == "https://discord.com/api/v9/channels/1486698771915083887/thread-members/@me")
    --                                                    && (method == "PUT")
    --
    --                                            _ ->
    --                                                False
    --                                    )
    --                                    data.httpRequests
    --                            of
    --                                [ _ ] ->
    --                                    [ T.websocketSendString
    --                                        100
    --                                        connection
    --                                        "{\"t\":\"THREAD_CREATE\",\"s\":8,\"op\":0,\"d\":{\"type\":11,\"total_message_sent\":0,\"thread_metadata\":{\"locked\":false,\"create_timestamp\":\"2026-03-26T12:10:08.752000+00:00\",\"auto_archive_duration\":4320,\"archived\":false,\"archive_timestamp\":\"2026-03-26T12:10:08.752000+00:00\"},\"rate_limit_per_user\":0,\"parent_id\":\"1072828564317159465\",\"owner_id\":\"161098476632014848\",\"name\":\"Thread starter\",\"message_count\":0,\"member_ids_preview\":[\"161098476632014848\",\"184437096813953035\"],\"member_count\":2,\"member\":{\"user_id\":\"184437096813953035\",\"muted\":false,\"mute_config\":null,\"join_timestamp\":\"2026-03-26T12:10:09.250111+00:00\",\"id\":\"1486698771915083887\",\"flags\":1},\"last_message_id\":null,\"id\":\"1486698771915083887\",\"guild_id\":\"705745250815311942\",\"flags\":0}}"
    --                                    , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Thread starter" ])
    --
    --                                    -- Click on thread to open it
    --                                    , admin.click 100 (Dom.id "guild_threadStarterIndicator_0")
    --
    --                                    -- No typing indicator yet
    --                                    , admin.checkView
    --                                        100
    --                                        (Test.Html.Query.hasNot
    --                                            [ Test.Html.Selector.exactText "at0232 is typing..." ]
    --                                        )
    --
    --                                    -- Send typing start in the thread channel
    --                                    , T.websocketSendString 100 connection "{\"t\":\"TYPING_START\",\"s\":9,\"op\":0,\"d\":{\"channel_id\":\"1486698771915083887\",\"guild_id\":\"705745250815311942\",\"user_id\":\"161098476632014848\",\"timestamp\":1}}"
    --                                    , admin.checkView
    --                                        100
    --                                        (Test.Html.Query.has
    --                                            [ Test.Html.Selector.exactText "at0232 is typing..." ]
    --                                        )
    --                                    ]
    --
    --                                _ ->
    --                                    [ T.checkBackend 100 (\_ -> Err "Didn't join thread") ]
    --                        )
    --                    ]
    --                )
    --            ]
    --        )
    --    ]
    ]
