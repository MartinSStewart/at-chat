module EndToEndTests exposing (main, setup)

import Backend
import Dict as RegularDict
import Duration
import Effect.Browser.Dom as Dom
import Effect.Lamdera as Lamdera exposing (SessionId)
import Effect.Test as T exposing (FileUpload(..), HttpRequest, HttpResponse(..), MultipleFilesUpload(..))
import EmailAddress exposing (EmailAddress)
import Env
import Frontend
import Json.Decode
import Json.Encode
import LoginForm
import Pages.Home
import Parser exposing ((|.), (|=))
import PersonName
import SeqDict
import Test.Html.Query
import Test.Html.Selector
import Time
import TwoFactorAuthentication
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, LoginTokenData(..), ToBackend, ToFrontend)
import Unsafe
import Url exposing (Url)


setup : T.ViewerWith (List (T.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel))
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
    if currentRequest.portName == "get_window_size" then
        Just
            ( "got_window_size"
            , Json.Encode.object
                [ ( "width", Json.Encode.float windowSize.width )
                , ( "height", Json.Encode.float windowSize.height )
                ]
            )

    else if currentRequest.portName == "elm_device_pixel_ratio_to_js" then
        Just ( "elm_device_pixel_ratio_from_js", Json.Encode.float 1 )

    else if currentRequest.portName == "text_input_select_all_to_js" then
        Nothing

    else if currentRequest.portName == "set_overscroll" then
        Nothing

    else
        let
            _ =
                Debug.log "port request" currentRequest
        in
        Nothing


windowSize : { width : number, height : number }
windowSize =
    { width = 1000, height = 1000 }


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


handleLogin :
    EmailAddress
    -> T.FrontendActions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> T.Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> T.Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
handleLogin emailAddress client =
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


tests : List (T.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
tests =
    let
        handleHttpRequests : ({ currentRequest : HttpRequest, data : T.Data FrontendModel BackendModel } -> Maybe HttpResponse) -> { currentRequest : HttpRequest, data : T.Data FrontendModel BackendModel } -> HttpResponse
        handleHttpRequests overrides ({ currentRequest } as httpRequests) =
            case overrides httpRequests of
                Just response ->
                    response

                Nothing ->
                    if currentRequest.url == "https://api.postmarkapp.com/email" then
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
    [ T.start "Enable 2FA"
        startTime
        config
        [ T.connectFrontend
            100
            sessionId0
            "/user-overview"
            windowSize
            (\user ->
                [ handleLogin Backend.adminUser.email user
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
                , user.click 100 (Dom.id "toolbar_logout")
                ]
            )
        , T.connectFrontend
            100
            sessionId0
            "/user-overview"
            windowSize
            (\user ->
                [ handleLogin Backend.adminUser.email user
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
                                                , user.checkView
                                                    100
                                                    (Test.Html.Query.has
                                                        [ Test.Html.Selector.exactText "Logged in as"
                                                        , Test.Html.Selector.exactText (PersonName.toString Backend.adminUser.name)
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
                            , user.input 100 LoginForm.emailInputId (EmailAddress.toString Backend.adminUser.email)
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
                        case List.filterMap (isLoginEmail Backend.adminUser.email) data.httpRequests of
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
                        case List.filterMap (isLoginEmail Backend.adminUser.email) data.httpRequests of
                            loginCode :: _ ->
                                [ user.input 100 LoginForm.loginCodeInputId (String.fromInt loginCode) ]

                            _ ->
                                [ T.checkState 100 (\_ -> Err "Didn't find login email") ]
                    )
                , user.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.exactText "Logged in as"
                        , Test.Html.Selector.exactText (PersonName.toString Backend.adminUser.name)
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
                , client.input 100 LoginForm.emailInputId (EmailAddress.toString Backend.adminUser.email)
                , client.snapshotView 100 { name = "valid email" }
                , client.click 100 LoginForm.submitEmailButtonId
                , T.andThen
                    100
                    (\data ->
                        case List.filterMap (isLoginEmail Backend.adminUser.email) data.httpRequests of
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


checkNoErrorLogs : T.Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> T.Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
checkNoErrorLogs instructions =
    T.checkState
        100
        (\data ->
            case List.filterMap (isLogErrorEmail Backend.emailToNotifyWhenErrorsAreLogged) data.httpRequests of
                [] ->
                    Ok ()

                errors ->
                    "Error logs detected: " ++ String.join ", " errors |> Err
        )
        instructions
