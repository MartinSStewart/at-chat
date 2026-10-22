module Evergreen.V408.SetViewing exposing (..)

import Evergreen.V408.Discord
import Evergreen.V408.DmChannel
import Evergreen.V408.Id
import Evergreen.V408.Message
import Evergreen.V408.Slack
import Evergreen.V408.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V408.UserSession.Viewing_DmData (Evergreen.V408.UserSession.ToBeFilledInByBackend Evergreen.V408.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V408.UserSession.Viewing_DmThreadData (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ThreadMessageId) (Evergreen.V408.Message.Message Evergreen.V408.Id.ThreadMessageId (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V408.UserSession.Viewing_DiscordDmData (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.Message.Message Evergreen.V408.Id.ChannelMessageId (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId))))
    | ViewChannel Evergreen.V408.UserSession.Viewing_ChannelData (Evergreen.V408.UserSession.ToBeFilledInByBackend Evergreen.V408.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V408.UserSession.Viewing_ChannelThreadData (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ThreadMessageId) (Evergreen.V408.Message.Message Evergreen.V408.Id.ThreadMessageId (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V408.UserSession.Viewing_DiscordChannelData (Evergreen.V408.UserSession.ToBeFilledInByBackend (Evergreen.V408.UserSession.ViewDiscordGuildData Evergreen.V408.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V408.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V408.UserSession.ToBeFilledInByBackend (Evergreen.V408.UserSession.ViewDiscordGuildData Evergreen.V408.Id.ThreadMessageId))
    | ViewSlackChannel Evergreen.V408.UserSession.Viewing_SlackChannelData (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.Message.Message Evergreen.V408.Id.ChannelMessageId (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId))))
    | ViewSlackDm Evergreen.V408.UserSession.Viewing_SlackDmData (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.Message.Message Evergreen.V408.Id.ChannelMessageId (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId))))
    | ViewSlackChannelThread Evergreen.V408.UserSession.Viewing_SlackChannelThreadData (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ThreadMessageId) (Evergreen.V408.Message.Message Evergreen.V408.Id.ThreadMessageId (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId))))
    | ViewSlackDmThread Evergreen.V408.UserSession.Viewing_SlackDmThreadData (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ThreadMessageId) (Evergreen.V408.Message.Message Evergreen.V408.Id.ThreadMessageId (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId))))
    | StopViewingChannel
    | ViewOverview (Evergreen.V408.UserSession.ToBeFilledInByBackend Evergreen.V408.UserSession.UnreadOverviewData)
