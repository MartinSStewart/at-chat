module Evergreen.V402.SetViewing exposing (..)

import Evergreen.V402.Discord
import Evergreen.V402.DmChannel
import Evergreen.V402.Id
import Evergreen.V402.Message
import Evergreen.V402.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V402.UserSession.Viewing_DmData (Evergreen.V402.UserSession.ToBeFilledInByBackend Evergreen.V402.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V402.UserSession.Viewing_DmThreadData (Evergreen.V402.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ThreadMessageId) (Evergreen.V402.Message.Message Evergreen.V402.Id.ThreadMessageId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V402.UserSession.Viewing_DiscordDmData (Evergreen.V402.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.Message.Message Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId))))
    | ViewChannel Evergreen.V402.UserSession.Viewing_ChannelData (Evergreen.V402.UserSession.ToBeFilledInByBackend Evergreen.V402.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V402.UserSession.Viewing_ChannelThreadData (Evergreen.V402.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ThreadMessageId) (Evergreen.V402.Message.Message Evergreen.V402.Id.ThreadMessageId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V402.UserSession.Viewing_DiscordChannelData (Evergreen.V402.UserSession.ToBeFilledInByBackend (Evergreen.V402.UserSession.ViewDiscordGuildData Evergreen.V402.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V402.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V402.UserSession.ToBeFilledInByBackend (Evergreen.V402.UserSession.ViewDiscordGuildData Evergreen.V402.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (Evergreen.V402.UserSession.ToBeFilledInByBackend Evergreen.V402.UserSession.UnreadOverviewData)
