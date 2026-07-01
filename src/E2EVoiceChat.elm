module E2EVoiceChat exposing (cloudflareCostTest, voiceChatTest)

import Array
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Log
import Test.Html.Query
import Test.Html.Selector
import Types exposing (BackendModel, BackendMsg, FrontendModel_, FrontendMsg_, ToBackend, ToFrontend)


voiceChatTest :
    T.Config ToBackend FrontendMsg_ FrontendModel_ ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg_ FrontendModel_ ToFrontend BackendMsg BackendModel
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
                    [ E2EHelper.addCloudflareRealtimeApiKeys admin
                    , admin.click 100 (Dom.id "guild_openDm_0")
                    , user.click 100 (Dom.id "guild_openDm_0")
                    , admin.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.text "started a call" ])
                    , admin.click 100 (Dom.id "guild_voiceChat")
                    , admin.click 100 (Dom.id "guild_startVoiceChat")
                    , E2EHelper.tallSnapshot admin 100 { name = "Started a DM call with self" }
                    , admin.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.text "started a call" ])
                    , admin.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.text "Call ended" ])
                    , E2EHelper.tallSnapshot admin 100 { name = "Ended a DM call with self" }
                    , admin.navigateBack 100
                    , admin.navigateBack 100
                    , admin.click 100 (Dom.id "guild_openDm_2")
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


cloudflareCostTest :
    T.Config ToBackend FrontendMsg_ FrontendModel_ ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg_ FrontendModel_ ToFrontend BackendMsg BackendModel
cloudflareCostTest config =
    E2EHelper.startTest
        "Cloudflare cost alert logs and emails the admin"
        E2EHelper.startTime
        config
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , E2EHelper.addCloudflareAnalyticsApiKeys admin

                -- The admin can also load current egress on demand from the voice chat section.
                , admin.click 100 (Dom.id "guild_showUserOptions")
                , admin.click 100 (Dom.id "userOptions_gotoAdmin")
                , admin.click 100 (Dom.id "admin_expandSectionButton_Voice chat")
                , admin.click 100 (Dom.id "admin_loadCloudflareEgress")
                , E2EHelper.hasText admin [ "1100.00 GB used (estimated $5.00 this month)" ]
                , admin.navigateBack 100
                ]
            )
        , -- The hourly job queries Cloudflare (mocked to return 1100 GB of egress => $5.00/month).
          T.backendUpdate 100 (Types.HourlyUpdate E2EHelper.startTime)
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
                case List.filterMap (E2EHelper.isLogErrorEmail E2EHelper.adminEmail) data.httpRequests of
                    log :: _ ->
                        if String.startsWith "Cloudflare services are estimated to cost" log then
                            Ok ()

                        else
                            Err ("Unexpected error email body: " ++ log)

                    [] ->
                        Err "Expected an error-notification email about Cloudflare costs"
            )
        ]
