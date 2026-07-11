module E2ELogin exposing (loginTests)

import Backend
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import EmailAddress
import LoginForm
import Pages.Home
import PersonName
import SeqDict
import Test.Html.Query
import Test.Html.Selector
import TwoFactorAuthentication
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, LoginTokenData(..), ToBackend, ToFrontend)


loginTests :
    Bool
    -> T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> List (T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
loginTests isMobile normalConfig =
    let
        windowSize : { width : number, height : number }
        windowSize =
            if isMobile then
                E2EHelper.iphone14Window

            else
                E2EHelper.desktopWindow

        userAgent =
            if isMobile then
                E2EHelper.safariIphone

            else
                E2EHelper.firefoxDesktop
    in
    [ E2EHelper.startTest
        (if isMobile then
            "Test login mobile"

         else
            "Test login"
        )
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            windowSize
            (\client ->
                [ T.andThen
                    10
                    (\data -> [ client.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data.time userAgent) ])
                , client.snapshotView 100 { name = "homepage" }
                , client.click 100 Pages.Home.loginButtonId
                , client.snapshotView 100 { name = "login" }
                , client.input 100 LoginForm.emailInputId "asdf123"
                , client.click 100 LoginForm.submitEmailButtonId
                , client.snapshotView 100 { name = "invalid email" }
                , client.input 100 LoginForm.emailInputId (EmailAddress.toString E2EHelper.adminEmail)
                , client.snapshotView 100 { name = "valid email" }
                , client.click 100 LoginForm.submitEmailButtonId
                , T.andThen
                    100
                    (\data ->
                        case List.filterMap (E2EHelper.isLoginEmail E2EHelper.adminEmail) data.httpRequests of
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
        , E2EHelper.checkNoErrorLogs
        ]
    , E2EHelper.startTest
        (if isMobile then
            "Enable 2FA mobile"

         else
            "Enable 2FA"
        )
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            windowSize
            (\user ->
                [ E2EHelper.handleLogin userAgent E2EHelper.adminEmail user
                , user.click 100 (Dom.id "guild_showUserOptions")
                , user.click 100 (Dom.id "userOverview_start2FaSetup")
                , E2EHelper.tallSnapshot user 100 { name = "2FA setup" }
                , user.input 100 (Dom.id "userOverview_twoFactorCodeInput") "123123"
                , E2EHelper.tallSnapshot user 100 { name = "2FA setup with wrong code" }
                , T.andThen
                    100
                    (\data ->
                        case SeqDict.get E2EHelper.sessionId0 data.backend.sessions of
                            Just { userId } ->
                                case SeqDict.get userId data.backend.twoFactorAuthenticationSetup of
                                    Just { secret } ->
                                        case TwoFactorAuthentication.getConfig "" secret of
                                            Ok key ->
                                                [ user.input
                                                    100
                                                    (Dom.id "userOverview_twoFactorCodeInput")
                                                    (TwoFactorAuthentication.getCode E2EHelper.startTime key
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
                                                , E2EHelper.tallSnapshot user 100 { name = "2FA setup complete" }
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
            E2EHelper.sessionId0
            "/"
            windowSize
            (\user ->
                [ E2EHelper.handleLogin userAgent E2EHelper.adminEmail user
                , E2EHelper.tallSnapshot user 100 { name = "2FA login step" }
                , T.andThen
                    100
                    (\data ->
                        case SeqDict.get E2EHelper.sessionId0 data.backend.pendingLogins of
                            Just (WaitingForTwoFactorToken { userId }) ->
                                case SeqDict.get userId data.backend.twoFactorAuthentication of
                                    Just { secret } ->
                                        case TwoFactorAuthentication.getConfig "" secret of
                                            Ok key ->
                                                [ user.input
                                                    100
                                                    (Dom.id "loginForm_twoFactorCodeInput")
                                                    (TwoFactorAuthentication.getCode E2EHelper.startTime key
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
                                                , E2EHelper.tallSnapshot user 100 { name = "user overview with two factor already complete" }
                                                , user.click 100 (Dom.id "userOverview_startDisable2Fa")
                                                , E2EHelper.tallSnapshot user 100 { name = "2FA disable prompt" }
                                                , user.input 100 (Dom.id "userOverview_disableTwoFactorCodeInput") "123123"
                                                , E2EHelper.tallSnapshot user 100 { name = "2FA disable with wrong code" }
                                                , user.input
                                                    100
                                                    (Dom.id "userOverview_disableTwoFactorCodeInput")
                                                    (TwoFactorAuthentication.getCode E2EHelper.startTime key
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
                                                , E2EHelper.tallSnapshot user 100 { name = "2FA disabled" }
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
