module Evergreen.V426.SetViewing exposing (..)

import Evergreen.V426.Discord
import Evergreen.V426.DmChannel
import Evergreen.V426.Id
import Evergreen.V426.Message
import Evergreen.V426.Slack
import Evergreen.V426.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V426.UserSession.Viewing_DmData (Evergreen.V426.UserSession.ToBeFilledInByBackend Evergreen.V426.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V426.UserSession.Viewing_DmThreadData (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ThreadMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ThreadMessageId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V426.UserSession.Viewing_DiscordDmData (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId))))
    | ViewChannel Evergreen.V426.UserSession.Viewing_ChannelData (Evergreen.V426.UserSession.ToBeFilledInByBackend Evergreen.V426.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V426.UserSession.Viewing_ChannelThreadData (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ThreadMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ThreadMessageId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V426.UserSession.Viewing_DiscordChannelData (Evergreen.V426.UserSession.ToBeFilledInByBackend (Evergreen.V426.UserSession.ViewDiscordGuildData Evergreen.V426.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V426.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V426.UserSession.ToBeFilledInByBackend (Evergreen.V426.UserSession.ViewDiscordGuildData Evergreen.V426.Id.ThreadMessageId))
    | ViewSlackChannel Evergreen.V426.UserSession.Viewing_SlackChannelData (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId))))
    | ViewSlackDm Evergreen.V426.UserSession.Viewing_SlackDmData (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId))))
    | ViewSlackChannelThread Evergreen.V426.UserSession.Viewing_SlackChannelThreadData (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ThreadMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ThreadMessageId (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId))))
    | ViewSlackDmThread Evergreen.V426.UserSession.Viewing_SlackDmThreadData (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ThreadMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ThreadMessageId (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId))))
    | StopViewingChannel
    | ViewOverview (Evergreen.V426.UserSession.ToBeFilledInByBackend Evergreen.V426.UserSession.UnreadOverviewData)
