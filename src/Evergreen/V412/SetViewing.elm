module Evergreen.V412.SetViewing exposing (..)

import Evergreen.V412.Discord
import Evergreen.V412.DmChannel
import Evergreen.V412.Id
import Evergreen.V412.Message
import Evergreen.V412.Slack
import Evergreen.V412.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V412.UserSession.Viewing_DmData (Evergreen.V412.UserSession.ToBeFilledInByBackend Evergreen.V412.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V412.UserSession.Viewing_DmThreadData (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ThreadMessageId) (Evergreen.V412.Message.Message Evergreen.V412.Id.ThreadMessageId (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V412.UserSession.Viewing_DiscordDmData (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.Message.Message Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId))))
    | ViewChannel Evergreen.V412.UserSession.Viewing_ChannelData (Evergreen.V412.UserSession.ToBeFilledInByBackend Evergreen.V412.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V412.UserSession.Viewing_ChannelThreadData (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ThreadMessageId) (Evergreen.V412.Message.Message Evergreen.V412.Id.ThreadMessageId (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V412.UserSession.Viewing_DiscordChannelData (Evergreen.V412.UserSession.ToBeFilledInByBackend (Evergreen.V412.UserSession.ViewDiscordGuildData Evergreen.V412.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V412.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V412.UserSession.ToBeFilledInByBackend (Evergreen.V412.UserSession.ViewDiscordGuildData Evergreen.V412.Id.ThreadMessageId))
    | ViewSlackChannel Evergreen.V412.UserSession.Viewing_SlackChannelData (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.Message.Message Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId))))
    | ViewSlackDm Evergreen.V412.UserSession.Viewing_SlackDmData (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.Message.Message Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId))))
    | ViewSlackChannelThread Evergreen.V412.UserSession.Viewing_SlackChannelThreadData (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ThreadMessageId) (Evergreen.V412.Message.Message Evergreen.V412.Id.ThreadMessageId (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId))))
    | ViewSlackDmThread Evergreen.V412.UserSession.Viewing_SlackDmThreadData (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ThreadMessageId) (Evergreen.V412.Message.Message Evergreen.V412.Id.ThreadMessageId (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId))))
    | StopViewingChannel
    | ViewOverview (Evergreen.V412.UserSession.ToBeFilledInByBackend Evergreen.V412.UserSession.UnreadOverviewData)
