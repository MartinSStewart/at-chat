module Evergreen.V414.SetViewing exposing (..)

import Evergreen.V414.Discord
import Evergreen.V414.DmChannel
import Evergreen.V414.Id
import Evergreen.V414.Message
import Evergreen.V414.Slack
import Evergreen.V414.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V414.UserSession.Viewing_DmData (Evergreen.V414.UserSession.ToBeFilledInByBackend Evergreen.V414.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V414.UserSession.Viewing_DmThreadData (Evergreen.V414.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ThreadMessageId) (Evergreen.V414.Message.Message Evergreen.V414.Id.ThreadMessageId (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V414.UserSession.Viewing_DiscordDmData (Evergreen.V414.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) (Evergreen.V414.Message.Message Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId))))
    | ViewChannel Evergreen.V414.UserSession.Viewing_ChannelData (Evergreen.V414.UserSession.ToBeFilledInByBackend Evergreen.V414.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V414.UserSession.Viewing_ChannelThreadData (Evergreen.V414.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ThreadMessageId) (Evergreen.V414.Message.Message Evergreen.V414.Id.ThreadMessageId (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V414.UserSession.Viewing_DiscordChannelData (Evergreen.V414.UserSession.ToBeFilledInByBackend (Evergreen.V414.UserSession.ViewDiscordGuildData Evergreen.V414.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V414.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V414.UserSession.ToBeFilledInByBackend (Evergreen.V414.UserSession.ViewDiscordGuildData Evergreen.V414.Id.ThreadMessageId))
    | ViewSlackChannel Evergreen.V414.UserSession.Viewing_SlackChannelData (Evergreen.V414.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) (Evergreen.V414.Message.Message Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Slack.Id Evergreen.V414.Slack.UserId) (Evergreen.V414.Slack.Id Evergreen.V414.Slack.ChannelId))))
    | ViewSlackDm Evergreen.V414.UserSession.Viewing_SlackDmData (Evergreen.V414.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) (Evergreen.V414.Message.Message Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Slack.Id Evergreen.V414.Slack.UserId) (Evergreen.V414.Slack.Id Evergreen.V414.Slack.ChannelId))))
    | ViewSlackChannelThread Evergreen.V414.UserSession.Viewing_SlackChannelThreadData (Evergreen.V414.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ThreadMessageId) (Evergreen.V414.Message.Message Evergreen.V414.Id.ThreadMessageId (Evergreen.V414.Slack.Id Evergreen.V414.Slack.UserId) (Evergreen.V414.Slack.Id Evergreen.V414.Slack.ChannelId))))
    | ViewSlackDmThread Evergreen.V414.UserSession.Viewing_SlackDmThreadData (Evergreen.V414.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ThreadMessageId) (Evergreen.V414.Message.Message Evergreen.V414.Id.ThreadMessageId (Evergreen.V414.Slack.Id Evergreen.V414.Slack.UserId) (Evergreen.V414.Slack.Id Evergreen.V414.Slack.ChannelId))))
    | StopViewingChannel
    | ViewOverview (Evergreen.V414.UserSession.ToBeFilledInByBackend Evergreen.V414.UserSession.UnreadOverviewData)
