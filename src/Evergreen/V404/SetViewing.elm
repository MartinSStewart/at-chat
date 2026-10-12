module Evergreen.V404.SetViewing exposing (..)

import Evergreen.V404.Discord
import Evergreen.V404.DmChannel
import Evergreen.V404.Id
import Evergreen.V404.Message
import Evergreen.V404.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V404.UserSession.Viewing_DmData (Evergreen.V404.UserSession.ToBeFilledInByBackend Evergreen.V404.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V404.UserSession.Viewing_DmThreadData (Evergreen.V404.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.ThreadMessageId) (Evergreen.V404.Message.Message Evergreen.V404.Id.ThreadMessageId (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V404.UserSession.Viewing_DiscordDmData (Evergreen.V404.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) (Evergreen.V404.Message.Message Evergreen.V404.Id.ChannelMessageId (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId))))
    | ViewChannel Evergreen.V404.UserSession.Viewing_ChannelData (Evergreen.V404.UserSession.ToBeFilledInByBackend Evergreen.V404.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V404.UserSession.Viewing_ChannelThreadData (Evergreen.V404.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.ThreadMessageId) (Evergreen.V404.Message.Message Evergreen.V404.Id.ThreadMessageId (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V404.UserSession.Viewing_DiscordChannelData (Evergreen.V404.UserSession.ToBeFilledInByBackend (Evergreen.V404.UserSession.ViewDiscordGuildData Evergreen.V404.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V404.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V404.UserSession.ToBeFilledInByBackend (Evergreen.V404.UserSession.ViewDiscordGuildData Evergreen.V404.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (Evergreen.V404.UserSession.ToBeFilledInByBackend Evergreen.V404.UserSession.UnreadOverviewData)
