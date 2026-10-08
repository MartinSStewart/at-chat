module Evergreen.V400.SetViewing exposing (..)

import Evergreen.V400.Discord
import Evergreen.V400.DmChannel
import Evergreen.V400.Id
import Evergreen.V400.Message
import Evergreen.V400.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V400.UserSession.Viewing_DmData (Evergreen.V400.UserSession.ToBeFilledInByBackend Evergreen.V400.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V400.UserSession.Viewing_DmThreadData (Evergreen.V400.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.ThreadMessageId) (Evergreen.V400.Message.Message Evergreen.V400.Id.ThreadMessageId (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V400.UserSession.Viewing_DiscordDmData (Evergreen.V400.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) (Evergreen.V400.Message.Message Evergreen.V400.Id.ChannelMessageId (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId))))
    | ViewChannel Evergreen.V400.UserSession.Viewing_ChannelData (Evergreen.V400.UserSession.ToBeFilledInByBackend Evergreen.V400.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V400.UserSession.Viewing_ChannelThreadData (Evergreen.V400.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.ThreadMessageId) (Evergreen.V400.Message.Message Evergreen.V400.Id.ThreadMessageId (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V400.UserSession.Viewing_DiscordChannelData (Evergreen.V400.UserSession.ToBeFilledInByBackend (Evergreen.V400.UserSession.ViewDiscordGuildData Evergreen.V400.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V400.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V400.UserSession.ToBeFilledInByBackend (Evergreen.V400.UserSession.ViewDiscordGuildData Evergreen.V400.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (Evergreen.V400.UserSession.ToBeFilledInByBackend Evergreen.V400.UserSession.UnreadOverviewData)
