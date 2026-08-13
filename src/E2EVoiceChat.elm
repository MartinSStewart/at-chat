module E2EVoiceChat exposing (voiceChatTest)

import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Test.Html.Query
import Test.Html.Selector
import Types exposing (BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)


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
                    , admin.click 100 (Dom.id "guild_startVoiceChat")
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
                    , admin.click 100 (Dom.id "guild_startVoiceChat")
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
                    , admin.click 100 (Dom.id "guild_startVoiceChat")
                    , user.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.text "started a call", Test.Html.Selector.text "Call ended" ])
                    ]
                )
            ]
        ]
