module Evergreen.V423.SetViewing exposing (..)

import Evergreen.V423.Discord
import Evergreen.V423.DmChannel
import Evergreen.V423.Id
import Evergreen.V423.Message
import Evergreen.V423.Slack
import Evergreen.V423.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V423.UserSession.Viewing_DmData (Evergreen.V423.UserSession.ToBeFilledInByBackend Evergreen.V423.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V423.UserSession.Viewing_DmThreadData (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ThreadMessageId) (Evergreen.V423.Message.Message Evergreen.V423.Id.ThreadMessageId (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V423.UserSession.Viewing_DiscordDmData (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.Message.Message Evergreen.V423.Id.ChannelMessageId (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId))))
    | ViewChannel Evergreen.V423.UserSession.Viewing_ChannelData (Evergreen.V423.UserSession.ToBeFilledInByBackend Evergreen.V423.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V423.UserSession.Viewing_ChannelThreadData (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ThreadMessageId) (Evergreen.V423.Message.Message Evergreen.V423.Id.ThreadMessageId (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V423.UserSession.Viewing_DiscordChannelData (Evergreen.V423.UserSession.ToBeFilledInByBackend (Evergreen.V423.UserSession.ViewDiscordGuildData Evergreen.V423.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V423.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V423.UserSession.ToBeFilledInByBackend (Evergreen.V423.UserSession.ViewDiscordGuildData Evergreen.V423.Id.ThreadMessageId))
    | ViewSlackChannel Evergreen.V423.UserSession.Viewing_SlackChannelData (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.Message.Message Evergreen.V423.Id.ChannelMessageId (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId))))
    | ViewSlackDm Evergreen.V423.UserSession.Viewing_SlackDmData (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.Message.Message Evergreen.V423.Id.ChannelMessageId (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId))))
    | ViewSlackChannelThread Evergreen.V423.UserSession.Viewing_SlackChannelThreadData (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ThreadMessageId) (Evergreen.V423.Message.Message Evergreen.V423.Id.ThreadMessageId (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId))))
    | ViewSlackDmThread Evergreen.V423.UserSession.Viewing_SlackDmThreadData (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ThreadMessageId) (Evergreen.V423.Message.Message Evergreen.V423.Id.ThreadMessageId (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId))))
    | StopViewingChannel
    | ViewOverview (Evergreen.V423.UserSession.ToBeFilledInByBackend Evergreen.V423.UserSession.UnreadOverviewData)
