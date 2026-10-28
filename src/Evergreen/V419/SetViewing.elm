module Evergreen.V419.SetViewing exposing (..)

import Evergreen.V419.Discord
import Evergreen.V419.DmChannel
import Evergreen.V419.Id
import Evergreen.V419.Message
import Evergreen.V419.Slack
import Evergreen.V419.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V419.UserSession.Viewing_DmData (Evergreen.V419.UserSession.ToBeFilledInByBackend Evergreen.V419.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V419.UserSession.Viewing_DmThreadData (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ThreadMessageId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V419.UserSession.Viewing_DiscordDmData (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId))))
    | ViewChannel Evergreen.V419.UserSession.Viewing_ChannelData (Evergreen.V419.UserSession.ToBeFilledInByBackend Evergreen.V419.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V419.UserSession.Viewing_ChannelThreadData (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ThreadMessageId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V419.UserSession.Viewing_DiscordChannelData (Evergreen.V419.UserSession.ToBeFilledInByBackend (Evergreen.V419.UserSession.ViewDiscordGuildData Evergreen.V419.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V419.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V419.UserSession.ToBeFilledInByBackend (Evergreen.V419.UserSession.ViewDiscordGuildData Evergreen.V419.Id.ThreadMessageId))
    | ViewSlackChannel Evergreen.V419.UserSession.Viewing_SlackChannelData (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId))))
    | ViewSlackDm Evergreen.V419.UserSession.Viewing_SlackDmData (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId))))
    | ViewSlackChannelThread Evergreen.V419.UserSession.Viewing_SlackChannelThreadData (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ThreadMessageId (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId))))
    | ViewSlackDmThread Evergreen.V419.UserSession.Viewing_SlackDmThreadData (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ThreadMessageId (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId))))
    | StopViewingChannel
    | ViewOverview (Evergreen.V419.UserSession.ToBeFilledInByBackend Evergreen.V419.UserSession.UnreadOverviewData)
