module Evergreen.V411.SetViewing exposing (..)

import Evergreen.V411.Discord
import Evergreen.V411.DmChannel
import Evergreen.V411.Id
import Evergreen.V411.Message
import Evergreen.V411.Slack
import Evergreen.V411.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V411.UserSession.Viewing_DmData (Evergreen.V411.UserSession.ToBeFilledInByBackend Evergreen.V411.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V411.UserSession.Viewing_DmThreadData (Evergreen.V411.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ThreadMessageId) (Evergreen.V411.Message.Message Evergreen.V411.Id.ThreadMessageId (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V411.UserSession.Viewing_DiscordDmData (Evergreen.V411.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) (Evergreen.V411.Message.Message Evergreen.V411.Id.ChannelMessageId (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId))))
    | ViewChannel Evergreen.V411.UserSession.Viewing_ChannelData (Evergreen.V411.UserSession.ToBeFilledInByBackend Evergreen.V411.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V411.UserSession.Viewing_ChannelThreadData (Evergreen.V411.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ThreadMessageId) (Evergreen.V411.Message.Message Evergreen.V411.Id.ThreadMessageId (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V411.UserSession.Viewing_DiscordChannelData (Evergreen.V411.UserSession.ToBeFilledInByBackend (Evergreen.V411.UserSession.ViewDiscordGuildData Evergreen.V411.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V411.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V411.UserSession.ToBeFilledInByBackend (Evergreen.V411.UserSession.ViewDiscordGuildData Evergreen.V411.Id.ThreadMessageId))
    | ViewSlackChannel Evergreen.V411.UserSession.Viewing_SlackChannelData (Evergreen.V411.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) (Evergreen.V411.Message.Message Evergreen.V411.Id.ChannelMessageId (Evergreen.V411.Slack.Id Evergreen.V411.Slack.UserId) (Evergreen.V411.Slack.Id Evergreen.V411.Slack.ChannelId))))
    | ViewSlackDm Evergreen.V411.UserSession.Viewing_SlackDmData (Evergreen.V411.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) (Evergreen.V411.Message.Message Evergreen.V411.Id.ChannelMessageId (Evergreen.V411.Slack.Id Evergreen.V411.Slack.UserId) (Evergreen.V411.Slack.Id Evergreen.V411.Slack.ChannelId))))
    | ViewSlackChannelThread Evergreen.V411.UserSession.Viewing_SlackChannelThreadData (Evergreen.V411.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ThreadMessageId) (Evergreen.V411.Message.Message Evergreen.V411.Id.ThreadMessageId (Evergreen.V411.Slack.Id Evergreen.V411.Slack.UserId) (Evergreen.V411.Slack.Id Evergreen.V411.Slack.ChannelId))))
    | ViewSlackDmThread Evergreen.V411.UserSession.Viewing_SlackDmThreadData (Evergreen.V411.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ThreadMessageId) (Evergreen.V411.Message.Message Evergreen.V411.Id.ThreadMessageId (Evergreen.V411.Slack.Id Evergreen.V411.Slack.UserId) (Evergreen.V411.Slack.Id Evergreen.V411.Slack.ChannelId))))
    | StopViewingChannel
    | ViewOverview (Evergreen.V411.UserSession.ToBeFilledInByBackend Evergreen.V411.UserSession.UnreadOverviewData)
