module Evergreen.V388.SetViewing exposing (..)

import Evergreen.V388.Discord
import Evergreen.V388.DmChannel
import Evergreen.V388.Id
import Evergreen.V388.Message
import Evergreen.V388.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V388.UserSession.Viewing_DmData (Evergreen.V388.UserSession.ToBeFilledInByBackend Evergreen.V388.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V388.UserSession.Viewing_DmThreadData (Evergreen.V388.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ThreadMessageId) (Evergreen.V388.Message.Message Evergreen.V388.Id.ThreadMessageId (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V388.UserSession.Viewing_DiscordDmData (Evergreen.V388.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.Message.Message Evergreen.V388.Id.ChannelMessageId (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId))))
    | ViewChannel Evergreen.V388.UserSession.Viewing_ChannelData (Evergreen.V388.UserSession.ToBeFilledInByBackend Evergreen.V388.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V388.UserSession.Viewing_ChannelThreadData (Evergreen.V388.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ThreadMessageId) (Evergreen.V388.Message.Message Evergreen.V388.Id.ThreadMessageId (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V388.UserSession.Viewing_DiscordChannelData (Evergreen.V388.UserSession.ToBeFilledInByBackend (Evergreen.V388.UserSession.ViewDiscordGuildData Evergreen.V388.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V388.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V388.UserSession.ToBeFilledInByBackend (Evergreen.V388.UserSession.ViewDiscordGuildData Evergreen.V388.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (Evergreen.V388.UserSession.ToBeFilledInByBackend Evergreen.V388.UserSession.UnreadOverviewData)
