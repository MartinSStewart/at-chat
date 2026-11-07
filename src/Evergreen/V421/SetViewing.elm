module Evergreen.V421.SetViewing exposing (..)

import Evergreen.V421.Discord
import Evergreen.V421.DmChannel
import Evergreen.V421.Id
import Evergreen.V421.Message
import Evergreen.V421.Slack
import Evergreen.V421.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V421.UserSession.Viewing_DmData (Evergreen.V421.UserSession.ToBeFilledInByBackend Evergreen.V421.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V421.UserSession.Viewing_DmThreadData (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ThreadMessageId) (Evergreen.V421.Message.Message Evergreen.V421.Id.ThreadMessageId (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V421.UserSession.Viewing_DiscordDmData (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.Message.Message Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId))))
    | ViewChannel Evergreen.V421.UserSession.Viewing_ChannelData (Evergreen.V421.UserSession.ToBeFilledInByBackend Evergreen.V421.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V421.UserSession.Viewing_ChannelThreadData (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ThreadMessageId) (Evergreen.V421.Message.Message Evergreen.V421.Id.ThreadMessageId (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V421.UserSession.Viewing_DiscordChannelData (Evergreen.V421.UserSession.ToBeFilledInByBackend (Evergreen.V421.UserSession.ViewDiscordGuildData Evergreen.V421.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V421.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V421.UserSession.ToBeFilledInByBackend (Evergreen.V421.UserSession.ViewDiscordGuildData Evergreen.V421.Id.ThreadMessageId))
    | ViewSlackChannel Evergreen.V421.UserSession.Viewing_SlackChannelData (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.Message.Message Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId))))
    | ViewSlackDm Evergreen.V421.UserSession.Viewing_SlackDmData (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.Message.Message Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId))))
    | ViewSlackChannelThread Evergreen.V421.UserSession.Viewing_SlackChannelThreadData (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ThreadMessageId) (Evergreen.V421.Message.Message Evergreen.V421.Id.ThreadMessageId (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId))))
    | ViewSlackDmThread Evergreen.V421.UserSession.Viewing_SlackDmThreadData (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ThreadMessageId) (Evergreen.V421.Message.Message Evergreen.V421.Id.ThreadMessageId (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId))))
    | StopViewingChannel
    | ViewOverview (Evergreen.V421.UserSession.ToBeFilledInByBackend Evergreen.V421.UserSession.UnreadOverviewData)
