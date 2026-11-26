module Evergreen.V425.SetViewing exposing (..)

import Evergreen.V425.Discord
import Evergreen.V425.DmChannel
import Evergreen.V425.Id
import Evergreen.V425.Message
import Evergreen.V425.Slack
import Evergreen.V425.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V425.UserSession.Viewing_DmData (Evergreen.V425.UserSession.ToBeFilledInByBackend Evergreen.V425.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V425.UserSession.Viewing_DmThreadData (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ThreadMessageId) (Evergreen.V425.Message.Message Evergreen.V425.Id.ThreadMessageId (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V425.UserSession.Viewing_DiscordDmData (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.Message.Message Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId))))
    | ViewChannel Evergreen.V425.UserSession.Viewing_ChannelData (Evergreen.V425.UserSession.ToBeFilledInByBackend Evergreen.V425.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V425.UserSession.Viewing_ChannelThreadData (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ThreadMessageId) (Evergreen.V425.Message.Message Evergreen.V425.Id.ThreadMessageId (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V425.UserSession.Viewing_DiscordChannelData (Evergreen.V425.UserSession.ToBeFilledInByBackend (Evergreen.V425.UserSession.ViewDiscordGuildData Evergreen.V425.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V425.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V425.UserSession.ToBeFilledInByBackend (Evergreen.V425.UserSession.ViewDiscordGuildData Evergreen.V425.Id.ThreadMessageId))
    | ViewSlackChannel Evergreen.V425.UserSession.Viewing_SlackChannelData (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.Message.Message Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId))))
    | ViewSlackDm Evergreen.V425.UserSession.Viewing_SlackDmData (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.Message.Message Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId))))
    | ViewSlackChannelThread Evergreen.V425.UserSession.Viewing_SlackChannelThreadData (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ThreadMessageId) (Evergreen.V425.Message.Message Evergreen.V425.Id.ThreadMessageId (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId))))
    | ViewSlackDmThread Evergreen.V425.UserSession.Viewing_SlackDmThreadData (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ThreadMessageId) (Evergreen.V425.Message.Message Evergreen.V425.Id.ThreadMessageId (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId))))
    | StopViewingChannel
    | ViewOverview (Evergreen.V425.UserSession.ToBeFilledInByBackend Evergreen.V425.UserSession.UnreadOverviewData)
