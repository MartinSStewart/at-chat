module Evergreen.V422.SetViewing exposing (..)

import Evergreen.V422.Discord
import Evergreen.V422.DmChannel
import Evergreen.V422.Id
import Evergreen.V422.Message
import Evergreen.V422.Slack
import Evergreen.V422.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V422.UserSession.Viewing_DmData (Evergreen.V422.UserSession.ToBeFilledInByBackend Evergreen.V422.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V422.UserSession.Viewing_DmThreadData (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ThreadMessageId) (Evergreen.V422.Message.Message Evergreen.V422.Id.ThreadMessageId (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V422.UserSession.Viewing_DiscordDmData (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.Message.Message Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId))))
    | ViewChannel Evergreen.V422.UserSession.Viewing_ChannelData (Evergreen.V422.UserSession.ToBeFilledInByBackend Evergreen.V422.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V422.UserSession.Viewing_ChannelThreadData (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ThreadMessageId) (Evergreen.V422.Message.Message Evergreen.V422.Id.ThreadMessageId (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V422.UserSession.Viewing_DiscordChannelData (Evergreen.V422.UserSession.ToBeFilledInByBackend (Evergreen.V422.UserSession.ViewDiscordGuildData Evergreen.V422.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V422.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V422.UserSession.ToBeFilledInByBackend (Evergreen.V422.UserSession.ViewDiscordGuildData Evergreen.V422.Id.ThreadMessageId))
    | ViewSlackChannel Evergreen.V422.UserSession.Viewing_SlackChannelData (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.Message.Message Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId))))
    | ViewSlackDm Evergreen.V422.UserSession.Viewing_SlackDmData (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.Message.Message Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId))))
    | ViewSlackChannelThread Evergreen.V422.UserSession.Viewing_SlackChannelThreadData (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ThreadMessageId) (Evergreen.V422.Message.Message Evergreen.V422.Id.ThreadMessageId (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId))))
    | ViewSlackDmThread Evergreen.V422.UserSession.Viewing_SlackDmThreadData (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ThreadMessageId) (Evergreen.V422.Message.Message Evergreen.V422.Id.ThreadMessageId (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId))))
    | StopViewingChannel
    | ViewOverview (Evergreen.V422.UserSession.ToBeFilledInByBackend Evergreen.V422.UserSession.UnreadOverviewData)
