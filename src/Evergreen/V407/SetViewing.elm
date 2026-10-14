module Evergreen.V407.SetViewing exposing (..)

import Evergreen.V407.Discord
import Evergreen.V407.DmChannel
import Evergreen.V407.Id
import Evergreen.V407.Message
import Evergreen.V407.Slack
import Evergreen.V407.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V407.UserSession.Viewing_DmData (Evergreen.V407.UserSession.ToBeFilledInByBackend Evergreen.V407.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V407.UserSession.Viewing_DmThreadData (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ThreadMessageId) (Evergreen.V407.Message.Message Evergreen.V407.Id.ThreadMessageId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V407.UserSession.Viewing_DiscordDmData (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId))))
    | ViewChannel Evergreen.V407.UserSession.Viewing_ChannelData (Evergreen.V407.UserSession.ToBeFilledInByBackend Evergreen.V407.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V407.UserSession.Viewing_ChannelThreadData (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ThreadMessageId) (Evergreen.V407.Message.Message Evergreen.V407.Id.ThreadMessageId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V407.UserSession.Viewing_DiscordChannelData (Evergreen.V407.UserSession.ToBeFilledInByBackend (Evergreen.V407.UserSession.ViewDiscordGuildData Evergreen.V407.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V407.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V407.UserSession.ToBeFilledInByBackend (Evergreen.V407.UserSession.ViewDiscordGuildData Evergreen.V407.Id.ThreadMessageId))
    | ViewSlackChannel Evergreen.V407.UserSession.Viewing_SlackChannelData (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId))))
    | ViewSlackDm Evergreen.V407.UserSession.Viewing_SlackDmData (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId))))
    | ViewSlackChannelThread Evergreen.V407.UserSession.Viewing_SlackChannelThreadData (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ThreadMessageId) (Evergreen.V407.Message.Message Evergreen.V407.Id.ThreadMessageId (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId))))
    | ViewSlackDmThread Evergreen.V407.UserSession.Viewing_SlackDmThreadData (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ThreadMessageId) (Evergreen.V407.Message.Message Evergreen.V407.Id.ThreadMessageId (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId))))
    | StopViewingChannel
    | ViewOverview (Evergreen.V407.UserSession.ToBeFilledInByBackend Evergreen.V407.UserSession.UnreadOverviewData)
