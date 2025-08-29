module EndToEndTests exposing (main, setup)

import Backend
import Dict as RegularDict
import Duration
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Lamdera as Lamdera exposing (SessionId)
import Effect.Test as T exposing (DelayInMs, FileUpload(..), HttpRequest, HttpResponse(..), MultipleFilesUpload(..))
import EmailAddress exposing (EmailAddress)
import Env
import Frontend
import Html.Attributes
import Id exposing (ChannelMessageId, Id, ThreadRouteWithMaybeMessage(..))
import Json.Decode
import Json.Encode
import List.Extra
import LoginForm
import Pages.Home
import Parser exposing ((|.), (|=))
import PersonName
import Route
import SeqDict
import Test.Html.Query
import Test.Html.Selector
import Time
import TwoFactorAuthentication
import Types exposing (BackendModel, BackendMsg, FrontendModel(..), FrontendMsg, LoadedFrontend, LoginTokenData(..), ToBackend, ToFrontend)
import Unsafe
import Url exposing (Url)


setup : T.ViewerWith (List (T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel))
setup =
    T.viewerWith tests


main : Program () (T.Model ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel) (T.Msg ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
main =
    T.startViewer setup


homepageUrl : Url
homepageUrl =
    Unsafe.url "https://my-website.com"


handlePortToJs :
    { currentRequest : T.PortToJs, data : T.Data FrontendModel BackendModel }
    -> Maybe ( String, Json.Decode.Value )
handlePortToJs { currentRequest } =
    case currentRequest.portName of
        "get_window_size" ->
            Just
                ( "got_window_size"
                , Json.Encode.object
                    [ ( "width", Json.Encode.float windowSize.width )
                    , ( "height", Json.Encode.float windowSize.height )
                    ]
                )

        "text_input_select_all_to_js" ->
            Nothing

        "check_notification_permission_to_js" ->
            Nothing

        "check_pwa_status_to_js" ->
            Just ( "check_pwa_status_from_js", Json.Encode.bool False )

        "is_push_subscription_registered_to_js" ->
            Just ( "is_push_subscription_registered_from_js", Json.Encode.bool False )

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

        _ ->
            let
                _ =
                    Debug.log "port request" currentRequest
            in
            Nothing


windowSize : { width : number, height : number }
windowSize =
    { width = 1000, height = 600 }


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


handleLogin :
    EmailAddress
    -> T.FrontendActions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> T.Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
handleLogin emailAddress client =
    [ client.click 100 Pages.Home.loginButtonId
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
        |> T.group


startTime : Time.Posix
startTime =
    Time.millisToPosix 0


adminEmail : EmailAddress
adminEmail =
    Unsafe.emailAddress Env.adminEmail


userEmail : EmailAddress
userEmail =
    Unsafe.emailAddress "user@mail.com"


enableNotifications : T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
enableNotifications user =
    [ user.click 100 (Dom.id "guild_showUserOptions")
    , user.click 100 (Dom.id "userOptions_togglePushNotifications")
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
                        List.any
                            (\( name, value ) -> name == "body" && value == body)
                            request.headers
                            && (request.url == "http://localhost:3000/file/push-notification")
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


dropPrefix : String -> String -> String
dropPrefix prefix text =
    if String.startsWith prefix text then
        String.dropLeft (String.length prefix) text

    else
        text


andThenFrontend :
    T.DelayInMs
    -> T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> (LoadedFrontend -> List (T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel))
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
andThenFrontend delay user func =
    T.andThen
        delay
        (\data ->
            case SeqDict.get user.clientId data.frontends of
                Just frontend ->
                    case frontend of
                        Loaded loaded ->
                            func loaded

                        Loading _ ->
                            [ T.checkState 0 (\_ -> Err "Frontend loading") ]

                Nothing ->
                    [ T.checkState 0 (\_ -> Err "Frontend missing") ]
        )


connectTwoUsers :
    (T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
     -> T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
     -> List (T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
    )
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
connectTwoUsers continueFunc =
    T.connectFrontend
        100
        sessionId0
        "/"
        windowSize
        (\admin ->
            [ handleLogin adminEmail admin
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
                                    [ handleLoginFromLoginPage userEmail user
                                    , user.input 100 (Dom.id "loginForm_name") "Stevie Steve"
                                    , user.click 100 (Dom.id "loginForm_submit")
                                    , user.click 100 (Dom.id "guild_openChannel_0")
                                    , enableNotifications user
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


writeMessage user text =
    T.group
        [ user.input 100 (Dom.id "channel_textinput") text
        , user.keyDown 100 (Dom.id "channel_textinput") "Enter" []
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


tests : List (T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
tests =
    let
        handleHttpRequests : ({ currentRequest : HttpRequest, data : T.Data FrontendModel BackendModel } -> Maybe HttpResponse) -> { currentRequest : HttpRequest, data : T.Data FrontendModel BackendModel } -> HttpResponse
        handleHttpRequests overrides ({ currentRequest } as httpRequests) =
            case overrides httpRequests of
                Just response ->
                    response

                Nothing ->
                    if currentRequest.url == "http://localhost:3000/file/vapid" then
                        StringHttpResponse
                            { url = currentRequest.url
                            , statusCode = 200
                            , statusText = "OK"
                            , headers = RegularDict.empty
                            }
                            "BIMi0iQoEXBXE3DyvGBToZfTfC8OyTn5lr_8eMvGBzJbxdEzv4wXFwIOEna_X3NJnCqIMbZX81VgSOFCjYda0bo,Ik2bRdqy_1dPMyiHxJX3_mV_t5R0GpQjsIu71E4MkCU"

                    else if currentRequest.url == "http://localhost:3000/file/push-notification" then
                        StringHttpResponse
                            { url = currentRequest.url
                            , statusCode = 200
                            , statusText = "OK"
                            , headers = RegularDict.empty
                            }
                            ""

                    else if currentRequest.url == "https://api.postmarkapp.com/email" then
                        case currentRequest.body of
                            T.JsonBody json ->
                                case Json.Decode.decodeValue (Json.Decode.field "To" Json.Decode.string) json of
                                    Ok email ->
                                        StringHttpResponse
                                            { url = currentRequest.url
                                            , statusCode = 200
                                            , statusText = "OK"
                                            , headers = RegularDict.empty
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

                    else
                        UnhandledHttpRequest

        handleFileRequest : { data : T.Data frontendModel backendModel, mimeTypes : List String } -> FileUpload
        handleFileRequest _ =
            UnhandledFileUpload

        handleMultiFileUpload : { data : T.Data frontendModel backendModel, mimeTypes : List String } -> MultipleFilesUpload
        handleMultiFileUpload _ =
            UnhandledMultiFileUpload

        config : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
        config =
            T.Config
                Frontend.app_
                Backend.app_
                (handleHttpRequests (\_ -> Nothing))
                handlePortToJs
                handleFileRequest
                handleMultiFileUpload
                homepageUrl
    in
    [ T.start
        "spoilers"
        startTime
        config
        [ connectTwoUsers
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
                , clickSpoiler admin (Dom.id "spoiler_0_0")
                , clickSpoiler admin (Dom.id "spoiler_0_2")
                ]
            )
        ]
    , T.start
        "Notifications"
        startTime
        config
        [ connectTwoUsers
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
                , checkNotification "@Stevie Steve Hi!"
                , enableNotifications admin
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
                , checkNotification "Hello admin!"
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
                ]
            )
        ]
    , T.start
        "Enable 2FA"
        startTime
        config
        [ T.connectFrontend
            100
            sessionId0
            "/"
            windowSize
            (\user ->
                [ handleLogin adminEmail user
                , user.click 100 (Dom.id "guild_showUserOptions")
                , user.click 100 (Dom.id "userOverview_start2FaSetup")
                , user.snapshotView 100 { name = "2FA setup" }
                , user.input 100 (Dom.id "userOverview_twoFactorCodeInput") "123123"
                , user.snapshotView 100 { name = "2FA setup with wrong code" }
                , T.andThen
                    100
                    (\data ->
                        case SeqDict.get sessionId0 data.backend.sessions of
                            Just userId ->
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
            windowSize
            (\user ->
                [ handleLogin adminEmail user
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
        config
        [ T.connectFrontend
            100
            sessionId0
            "/"
            windowSize
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
                [ openLoginAndSubmitEmail 100
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
                , [ user.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.text "Too many login attempts have been made." ])
                  , openLoginAndSubmitEmail 100
                  ]
                    |> T.group
                    |> List.repeat 6
                    |> T.group
                , user.checkView
                    100
                    (Test.Html.Query.has [ Test.Html.Selector.text "Too many login attempts have been made." ])
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
                , user.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.exactText (PersonName.toString Backend.adminUser.name)
                        ]
                    )
                ]
            )
        , T.checkState
            (Duration.hours 4.01 |> Duration.inMilliseconds)
            (\data ->
                case
                    List.filterMap
                        (isLogErrorEmail Backend.emailToNotifyWhenErrorsAreLogged)
                        data.httpRequests
                of
                    [ "LoginsRateLimited" ] ->
                        Ok ()

                    _ ->
                        Err "Expected to only see LoginsRateLimited as an error email"
            )
        ]
    , T.start "Test login"
        startTime
        config
        [ T.connectFrontend
            100
            sessionId0
            "/"
            windowSize
            (\client ->
                [ client.snapshotView 100 { name = "homepage" }
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
    ]


checkNoErrorLogs : T.Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
checkNoErrorLogs =
    T.checkState
        100
        (\data ->
            case List.filterMap (isLogErrorEmail Backend.emailToNotifyWhenErrorsAreLogged) data.httpRequests of
                [] ->
                    Ok ()

                errors ->
                    "Error logs detected: " ++ String.join ", " errors |> Err
        )
