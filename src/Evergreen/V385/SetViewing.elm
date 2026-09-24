module Evergreen.V385.SetViewing exposing (..)

import Evergreen.V385.Discord
import Evergreen.V385.DmChannel
import Evergreen.V385.Id
import Evergreen.V385.Message
import Evergreen.V385.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V385.UserSession.Viewing_DmData (Evergreen.V385.UserSession.ToBeFilledInByBackend Evergreen.V385.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V385.UserSession.Viewing_DmThreadData (Evergreen.V385.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ThreadMessageId) (Evergreen.V385.Message.Message Evergreen.V385.Id.ThreadMessageId (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))))
    | ViewDiscordDm Evergreen.V385.UserSession.Viewing_DiscordDmData (Evergreen.V385.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.Message.Message Evergreen.V385.Id.ChannelMessageId (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId))))
    | ViewChannel Evergreen.V385.UserSession.Viewing_ChannelData (Evergreen.V385.UserSession.ToBeFilledInByBackend Evergreen.V385.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V385.UserSession.Viewing_ChannelThreadData (Evergreen.V385.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ThreadMessageId) (Evergreen.V385.Message.Message Evergreen.V385.Id.ThreadMessageId (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))))
    | ViewDiscordChannel Evergreen.V385.UserSession.Viewing_DiscordChannelData (Evergreen.V385.UserSession.ToBeFilledInByBackend (Evergreen.V385.UserSession.ViewDiscordGuildData Evergreen.V385.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V385.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V385.UserSession.ToBeFilledInByBackend (Evergreen.V385.UserSession.ViewDiscordGuildData Evergreen.V385.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (Evergreen.V385.UserSession.ToBeFilledInByBackend Evergreen.V385.UserSession.UnreadOverviewData)
