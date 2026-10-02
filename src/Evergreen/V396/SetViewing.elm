module Evergreen.V396.SetViewing exposing (..)

import Evergreen.V396.Discord
import Evergreen.V396.DmChannel
import Evergreen.V396.Id
import Evergreen.V396.Message
import Evergreen.V396.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V396.UserSession.Viewing_DmData (Evergreen.V396.UserSession.ToBeFilledInByBackend Evergreen.V396.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V396.UserSession.Viewing_DmThreadData (Evergreen.V396.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ThreadMessageId) (Evergreen.V396.Message.Message Evergreen.V396.Id.ThreadMessageId (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V396.UserSession.Viewing_DiscordDmData (Evergreen.V396.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.Message.Message Evergreen.V396.Id.ChannelMessageId (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId))))
    | ViewChannel Evergreen.V396.UserSession.Viewing_ChannelData (Evergreen.V396.UserSession.ToBeFilledInByBackend Evergreen.V396.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V396.UserSession.Viewing_ChannelThreadData (Evergreen.V396.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ThreadMessageId) (Evergreen.V396.Message.Message Evergreen.V396.Id.ThreadMessageId (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V396.UserSession.Viewing_DiscordChannelData (Evergreen.V396.UserSession.ToBeFilledInByBackend (Evergreen.V396.UserSession.ViewDiscordGuildData Evergreen.V396.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V396.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V396.UserSession.ToBeFilledInByBackend (Evergreen.V396.UserSession.ViewDiscordGuildData Evergreen.V396.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (Evergreen.V396.UserSession.ToBeFilledInByBackend Evergreen.V396.UserSession.UnreadOverviewData)
