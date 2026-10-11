module Evergreen.V403.SetViewing exposing (..)

import Evergreen.V403.Discord
import Evergreen.V403.DmChannel
import Evergreen.V403.Id
import Evergreen.V403.Message
import Evergreen.V403.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V403.UserSession.Viewing_DmData (Evergreen.V403.UserSession.ToBeFilledInByBackend Evergreen.V403.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V403.UserSession.Viewing_DmThreadData (Evergreen.V403.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ThreadMessageId) (Evergreen.V403.Message.Message Evergreen.V403.Id.ThreadMessageId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V403.UserSession.Viewing_DiscordDmData (Evergreen.V403.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.Message.Message Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId))))
    | ViewChannel Evergreen.V403.UserSession.Viewing_ChannelData (Evergreen.V403.UserSession.ToBeFilledInByBackend Evergreen.V403.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V403.UserSession.Viewing_ChannelThreadData (Evergreen.V403.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ThreadMessageId) (Evergreen.V403.Message.Message Evergreen.V403.Id.ThreadMessageId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V403.UserSession.Viewing_DiscordChannelData (Evergreen.V403.UserSession.ToBeFilledInByBackend (Evergreen.V403.UserSession.ViewDiscordGuildData Evergreen.V403.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V403.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V403.UserSession.ToBeFilledInByBackend (Evergreen.V403.UserSession.ViewDiscordGuildData Evergreen.V403.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (Evergreen.V403.UserSession.ToBeFilledInByBackend Evergreen.V403.UserSession.UnreadOverviewData)
