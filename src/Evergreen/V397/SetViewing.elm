module Evergreen.V397.SetViewing exposing (..)

import Evergreen.V397.Discord
import Evergreen.V397.DmChannel
import Evergreen.V397.Id
import Evergreen.V397.Message
import Evergreen.V397.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V397.UserSession.Viewing_DmData (Evergreen.V397.UserSession.ToBeFilledInByBackend Evergreen.V397.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V397.UserSession.Viewing_DmThreadData (Evergreen.V397.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ThreadMessageId) (Evergreen.V397.Message.Message Evergreen.V397.Id.ThreadMessageId (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V397.UserSession.Viewing_DiscordDmData (Evergreen.V397.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.Message.Message Evergreen.V397.Id.ChannelMessageId (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId))))
    | ViewChannel Evergreen.V397.UserSession.Viewing_ChannelData (Evergreen.V397.UserSession.ToBeFilledInByBackend Evergreen.V397.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V397.UserSession.Viewing_ChannelThreadData (Evergreen.V397.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ThreadMessageId) (Evergreen.V397.Message.Message Evergreen.V397.Id.ThreadMessageId (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V397.UserSession.Viewing_DiscordChannelData (Evergreen.V397.UserSession.ToBeFilledInByBackend (Evergreen.V397.UserSession.ViewDiscordGuildData Evergreen.V397.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V397.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V397.UserSession.ToBeFilledInByBackend (Evergreen.V397.UserSession.ViewDiscordGuildData Evergreen.V397.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (Evergreen.V397.UserSession.ToBeFilledInByBackend Evergreen.V397.UserSession.UnreadOverviewData)
