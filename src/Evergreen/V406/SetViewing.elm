module Evergreen.V406.SetViewing exposing (..)

import Evergreen.V406.Discord
import Evergreen.V406.DmChannel
import Evergreen.V406.Id
import Evergreen.V406.Message
import Evergreen.V406.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V406.UserSession.Viewing_DmData (Evergreen.V406.UserSession.ToBeFilledInByBackend Evergreen.V406.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V406.UserSession.Viewing_DmThreadData (Evergreen.V406.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ThreadMessageId) (Evergreen.V406.Message.Message Evergreen.V406.Id.ThreadMessageId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V406.UserSession.Viewing_DiscordDmData (Evergreen.V406.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.Message.Message Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId))))
    | ViewChannel Evergreen.V406.UserSession.Viewing_ChannelData (Evergreen.V406.UserSession.ToBeFilledInByBackend Evergreen.V406.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V406.UserSession.Viewing_ChannelThreadData (Evergreen.V406.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ThreadMessageId) (Evergreen.V406.Message.Message Evergreen.V406.Id.ThreadMessageId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V406.UserSession.Viewing_DiscordChannelData (Evergreen.V406.UserSession.ToBeFilledInByBackend (Evergreen.V406.UserSession.ViewDiscordGuildData Evergreen.V406.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V406.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V406.UserSession.ToBeFilledInByBackend (Evergreen.V406.UserSession.ViewDiscordGuildData Evergreen.V406.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (Evergreen.V406.UserSession.ToBeFilledInByBackend Evergreen.V406.UserSession.UnreadOverviewData)
