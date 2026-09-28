module Evergreen.V389.SetViewing exposing (..)

import Evergreen.V389.Discord
import Evergreen.V389.DmChannel
import Evergreen.V389.Id
import Evergreen.V389.Message
import Evergreen.V389.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V389.UserSession.Viewing_DmData (Evergreen.V389.UserSession.ToBeFilledInByBackend Evergreen.V389.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V389.UserSession.Viewing_DmThreadData (Evergreen.V389.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ThreadMessageId) (Evergreen.V389.Message.Message Evergreen.V389.Id.ThreadMessageId (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V389.UserSession.Viewing_DiscordDmData (Evergreen.V389.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.Message.Message Evergreen.V389.Id.ChannelMessageId (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId))))
    | ViewChannel Evergreen.V389.UserSession.Viewing_ChannelData (Evergreen.V389.UserSession.ToBeFilledInByBackend Evergreen.V389.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V389.UserSession.Viewing_ChannelThreadData (Evergreen.V389.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ThreadMessageId) (Evergreen.V389.Message.Message Evergreen.V389.Id.ThreadMessageId (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V389.UserSession.Viewing_DiscordChannelData (Evergreen.V389.UserSession.ToBeFilledInByBackend (Evergreen.V389.UserSession.ViewDiscordGuildData Evergreen.V389.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V389.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V389.UserSession.ToBeFilledInByBackend (Evergreen.V389.UserSession.ViewDiscordGuildData Evergreen.V389.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (Evergreen.V389.UserSession.ToBeFilledInByBackend Evergreen.V389.UserSession.UnreadOverviewData)
