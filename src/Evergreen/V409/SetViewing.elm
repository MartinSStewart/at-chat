module Evergreen.V409.SetViewing exposing (..)

import Evergreen.V409.Discord
import Evergreen.V409.DmChannel
import Evergreen.V409.Id
import Evergreen.V409.Message
import Evergreen.V409.Slack
import Evergreen.V409.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V409.UserSession.Viewing_DmData (Evergreen.V409.UserSession.ToBeFilledInByBackend Evergreen.V409.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V409.UserSession.Viewing_DmThreadData (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ThreadMessageId) (Evergreen.V409.Message.Message Evergreen.V409.Id.ThreadMessageId (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V409.UserSession.Viewing_DiscordDmData (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.Message.Message Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId))))
    | ViewChannel Evergreen.V409.UserSession.Viewing_ChannelData (Evergreen.V409.UserSession.ToBeFilledInByBackend Evergreen.V409.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V409.UserSession.Viewing_ChannelThreadData (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ThreadMessageId) (Evergreen.V409.Message.Message Evergreen.V409.Id.ThreadMessageId (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V409.UserSession.Viewing_DiscordChannelData (Evergreen.V409.UserSession.ToBeFilledInByBackend (Evergreen.V409.UserSession.ViewDiscordGuildData Evergreen.V409.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V409.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V409.UserSession.ToBeFilledInByBackend (Evergreen.V409.UserSession.ViewDiscordGuildData Evergreen.V409.Id.ThreadMessageId))
    | ViewSlackChannel Evergreen.V409.UserSession.Viewing_SlackChannelData (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.Message.Message Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId))))
    | ViewSlackDm Evergreen.V409.UserSession.Viewing_SlackDmData (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.Message.Message Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId))))
    | ViewSlackChannelThread Evergreen.V409.UserSession.Viewing_SlackChannelThreadData (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ThreadMessageId) (Evergreen.V409.Message.Message Evergreen.V409.Id.ThreadMessageId (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId))))
    | ViewSlackDmThread Evergreen.V409.UserSession.Viewing_SlackDmThreadData (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ThreadMessageId) (Evergreen.V409.Message.Message Evergreen.V409.Id.ThreadMessageId (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId))))
    | StopViewingChannel
    | ViewOverview (Evergreen.V409.UserSession.ToBeFilledInByBackend Evergreen.V409.UserSession.UnreadOverviewData)
