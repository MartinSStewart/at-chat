module Evergreen.V405.SetViewing exposing (..)

import Evergreen.V405.Discord
import Evergreen.V405.DmChannel
import Evergreen.V405.Id
import Evergreen.V405.Message
import Evergreen.V405.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V405.UserSession.Viewing_DmData (Evergreen.V405.UserSession.ToBeFilledInByBackend Evergreen.V405.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V405.UserSession.Viewing_DmThreadData (Evergreen.V405.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ThreadMessageId) (Evergreen.V405.Message.Message Evergreen.V405.Id.ThreadMessageId (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V405.UserSession.Viewing_DiscordDmData (Evergreen.V405.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.Message.Message Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId))))
    | ViewChannel Evergreen.V405.UserSession.Viewing_ChannelData (Evergreen.V405.UserSession.ToBeFilledInByBackend Evergreen.V405.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V405.UserSession.Viewing_ChannelThreadData (Evergreen.V405.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ThreadMessageId) (Evergreen.V405.Message.Message Evergreen.V405.Id.ThreadMessageId (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V405.UserSession.Viewing_DiscordChannelData (Evergreen.V405.UserSession.ToBeFilledInByBackend (Evergreen.V405.UserSession.ViewDiscordGuildData Evergreen.V405.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V405.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V405.UserSession.ToBeFilledInByBackend (Evergreen.V405.UserSession.ViewDiscordGuildData Evergreen.V405.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (Evergreen.V405.UserSession.ToBeFilledInByBackend Evergreen.V405.UserSession.UnreadOverviewData)
