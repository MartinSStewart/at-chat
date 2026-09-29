module Evergreen.V394.SetViewing exposing (..)

import Evergreen.V394.Discord
import Evergreen.V394.DmChannel
import Evergreen.V394.Id
import Evergreen.V394.Message
import Evergreen.V394.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V394.UserSession.Viewing_DmData (Evergreen.V394.UserSession.ToBeFilledInByBackend Evergreen.V394.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V394.UserSession.Viewing_DmThreadData (Evergreen.V394.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ThreadMessageId) (Evergreen.V394.Message.Message Evergreen.V394.Id.ThreadMessageId (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V394.UserSession.Viewing_DiscordDmData (Evergreen.V394.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.Message.Message Evergreen.V394.Id.ChannelMessageId (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId))))
    | ViewChannel Evergreen.V394.UserSession.Viewing_ChannelData (Evergreen.V394.UserSession.ToBeFilledInByBackend Evergreen.V394.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V394.UserSession.Viewing_ChannelThreadData (Evergreen.V394.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ThreadMessageId) (Evergreen.V394.Message.Message Evergreen.V394.Id.ThreadMessageId (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V394.UserSession.Viewing_DiscordChannelData (Evergreen.V394.UserSession.ToBeFilledInByBackend (Evergreen.V394.UserSession.ViewDiscordGuildData Evergreen.V394.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V394.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V394.UserSession.ToBeFilledInByBackend (Evergreen.V394.UserSession.ViewDiscordGuildData Evergreen.V394.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (Evergreen.V394.UserSession.ToBeFilledInByBackend Evergreen.V394.UserSession.UnreadOverviewData)
