module Evergreen.V417.SetViewing exposing (..)

import Evergreen.V417.Discord
import Evergreen.V417.DmChannel
import Evergreen.V417.Id
import Evergreen.V417.Message
import Evergreen.V417.Slack
import Evergreen.V417.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V417.UserSession.Viewing_DmData (Evergreen.V417.UserSession.ToBeFilledInByBackend Evergreen.V417.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V417.UserSession.Viewing_DmThreadData (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ThreadMessageId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V417.UserSession.Viewing_DiscordDmData (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId))))
    | ViewChannel Evergreen.V417.UserSession.Viewing_ChannelData (Evergreen.V417.UserSession.ToBeFilledInByBackend Evergreen.V417.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V417.UserSession.Viewing_ChannelThreadData (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ThreadMessageId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V417.UserSession.Viewing_DiscordChannelData (Evergreen.V417.UserSession.ToBeFilledInByBackend (Evergreen.V417.UserSession.ViewDiscordGuildData Evergreen.V417.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V417.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V417.UserSession.ToBeFilledInByBackend (Evergreen.V417.UserSession.ViewDiscordGuildData Evergreen.V417.Id.ThreadMessageId))
    | ViewSlackChannel Evergreen.V417.UserSession.Viewing_SlackChannelData (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId))))
    | ViewSlackDm Evergreen.V417.UserSession.Viewing_SlackDmData (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId))))
    | ViewSlackChannelThread Evergreen.V417.UserSession.Viewing_SlackChannelThreadData (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ThreadMessageId (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId))))
    | ViewSlackDmThread Evergreen.V417.UserSession.Viewing_SlackDmThreadData (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ThreadMessageId (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId))))
    | StopViewingChannel
    | ViewOverview (Evergreen.V417.UserSession.ToBeFilledInByBackend Evergreen.V417.UserSession.UnreadOverviewData)
