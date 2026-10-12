module E2ESlack exposing (linkSlackLoadsChannelsTest)

import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Pages.Admin
import SeqDict
import Slack
import Types exposing (BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)


linkSlackLoadsChannelsTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
linkSlackLoadsChannelsTest config =
    E2EHelper.startTest
        "Linking Slack loads each workspace's channels and the admin page lists them"
        E2EHelper.startTime
        config
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , admin.click 1000 (Dom.id "guild_showUserOptions")
                , admin.click 100 (Dom.id "userOptions_slackSection")
                , admin.input 100 (Dom.id "userOptions_slackCookie") E2EHelper.legitSlackCookie
                , admin.input
                    100
                    (Dom.id "userOptions_slackTeamsJson")
                    ("{\"T09DJDQL18U\":{\"token\":\""
                        ++ E2EHelper.legitSlackToken
                        ++ "\"},\"T0EXPIRED\":{\"token\":\"xoxc-expired-token\"}}"
                    )
                , admin.click 100 (Dom.id "userOptions_submitSlackData")
                , E2EHelper.hasExactText
                    admin
                    [ "Loaded test-slack", "Couldn't load a workspace: Slack said invalid_auth" ]
                , T.checkBackend
                    100
                    (\backend ->
                        case
                            SeqDict.values (E2EHelper.unwrapBackend backend).slackWorkspaces
                                |> List.map (\workspace -> SeqDict.keys workspace.channels |> List.map Slack.idToString)
                        of
                            [ [ "C09DJDQSWLU", "C09DJDQUKKN", "C0C8993MS6N" ] ] ->
                                Ok ()

                            channels ->
                                Err
                                    ("Expected one workspace with every page of channels, got "
                                        ++ String.join " | " (List.map (String.join ", ") channels)
                                    )
                    )
                , admin.click 100 (Dom.id "userOptions_gotoAdmin")
                , admin.click 100 (Pages.Admin.expandSectionButtonId Pages.Admin.SlackWorkspacesSection)
                , E2EHelper.hasExactText admin [ "test-slack", "Channels: 3", "slack-admin" ]
                , E2EHelper.hasNotExactText admin [ "#social" ]
                , admin.click 100 (Pages.Admin.expandSlackWorkspaceButtonId (Slack.Id "T09DJDQL18U"))
                , E2EHelper.hasExactText admin [ "#all-test-slack", "#social", "#newer-channel" ]
                , admin.click 100 (Pages.Admin.deleteSlackWorkspaceButtonId (Slack.Id "T09DJDQL18U"))
                , E2EHelper.hasExactText admin [ "No Slack workspaces" ]
                , T.checkBackend
                    100
                    (\backend ->
                        if SeqDict.isEmpty (E2EHelper.unwrapBackend backend).slackWorkspaces then
                            Ok ()

                        else
                            Err "Deleting the workspace in the admin page should remove it from the backend"
                    )
                ]
            )
        ]
