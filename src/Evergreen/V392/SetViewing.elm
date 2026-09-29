module Evergreen.V392.SetViewing exposing (..)

import Evergreen.V392.Discord
import Evergreen.V392.DmChannel
import Evergreen.V392.Id
import Evergreen.V392.Message
import Evergreen.V392.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V392.UserSession.Viewing_DmData (Evergreen.V392.UserSession.ToBeFilledInByBackend Evergreen.V392.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V392.UserSession.Viewing_DmThreadData (Evergreen.V392.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ThreadMessageId) (Evergreen.V392.Message.Message Evergreen.V392.Id.ThreadMessageId (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V392.UserSession.Viewing_DiscordDmData (Evergreen.V392.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.Message.Message Evergreen.V392.Id.ChannelMessageId (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId))))
    | ViewChannel Evergreen.V392.UserSession.Viewing_ChannelData (Evergreen.V392.UserSession.ToBeFilledInByBackend Evergreen.V392.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V392.UserSession.Viewing_ChannelThreadData (Evergreen.V392.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ThreadMessageId) (Evergreen.V392.Message.Message Evergreen.V392.Id.ThreadMessageId (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V392.UserSession.Viewing_DiscordChannelData (Evergreen.V392.UserSession.ToBeFilledInByBackend (Evergreen.V392.UserSession.ViewDiscordGuildData Evergreen.V392.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V392.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V392.UserSession.ToBeFilledInByBackend (Evergreen.V392.UserSession.ViewDiscordGuildData Evergreen.V392.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (Evergreen.V392.UserSession.ToBeFilledInByBackend Evergreen.V392.UserSession.UnreadOverviewData)
