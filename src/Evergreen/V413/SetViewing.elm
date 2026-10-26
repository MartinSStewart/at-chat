module Evergreen.V413.SetViewing exposing (..)

import Evergreen.V413.Discord
import Evergreen.V413.DmChannel
import Evergreen.V413.Id
import Evergreen.V413.Message
import Evergreen.V413.Slack
import Evergreen.V413.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V413.UserSession.Viewing_DmData (Evergreen.V413.UserSession.ToBeFilledInByBackend Evergreen.V413.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V413.UserSession.Viewing_DmThreadData (Evergreen.V413.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ThreadMessageId) (Evergreen.V413.Message.Message Evergreen.V413.Id.ThreadMessageId (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V413.UserSession.Viewing_DiscordDmData (Evergreen.V413.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.Message.Message Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId))))
    | ViewChannel Evergreen.V413.UserSession.Viewing_ChannelData (Evergreen.V413.UserSession.ToBeFilledInByBackend Evergreen.V413.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V413.UserSession.Viewing_ChannelThreadData (Evergreen.V413.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ThreadMessageId) (Evergreen.V413.Message.Message Evergreen.V413.Id.ThreadMessageId (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V413.UserSession.Viewing_DiscordChannelData (Evergreen.V413.UserSession.ToBeFilledInByBackend (Evergreen.V413.UserSession.ViewDiscordGuildData Evergreen.V413.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V413.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V413.UserSession.ToBeFilledInByBackend (Evergreen.V413.UserSession.ViewDiscordGuildData Evergreen.V413.Id.ThreadMessageId))
    | ViewSlackChannel Evergreen.V413.UserSession.Viewing_SlackChannelData (Evergreen.V413.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.Message.Message Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId))))
    | ViewSlackDm Evergreen.V413.UserSession.Viewing_SlackDmData (Evergreen.V413.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.Message.Message Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId))))
    | ViewSlackChannelThread Evergreen.V413.UserSession.Viewing_SlackChannelThreadData (Evergreen.V413.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ThreadMessageId) (Evergreen.V413.Message.Message Evergreen.V413.Id.ThreadMessageId (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId))))
    | ViewSlackDmThread Evergreen.V413.UserSession.Viewing_SlackDmThreadData (Evergreen.V413.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ThreadMessageId) (Evergreen.V413.Message.Message Evergreen.V413.Id.ThreadMessageId (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId))))
    | StopViewingChannel
    | ViewOverview (Evergreen.V413.UserSession.ToBeFilledInByBackend Evergreen.V413.UserSession.UnreadOverviewData)
