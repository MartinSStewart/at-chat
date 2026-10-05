module Evergreen.V398.SetViewing exposing (..)

import Evergreen.V398.Discord
import Evergreen.V398.DmChannel
import Evergreen.V398.Id
import Evergreen.V398.Message
import Evergreen.V398.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V398.UserSession.Viewing_DmData (Evergreen.V398.UserSession.ToBeFilledInByBackend Evergreen.V398.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V398.UserSession.Viewing_DmThreadData (Evergreen.V398.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ThreadMessageId) (Evergreen.V398.Message.Message Evergreen.V398.Id.ThreadMessageId (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V398.UserSession.Viewing_DiscordDmData (Evergreen.V398.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.Message.Message Evergreen.V398.Id.ChannelMessageId (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId))))
    | ViewChannel Evergreen.V398.UserSession.Viewing_ChannelData (Evergreen.V398.UserSession.ToBeFilledInByBackend Evergreen.V398.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V398.UserSession.Viewing_ChannelThreadData (Evergreen.V398.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ThreadMessageId) (Evergreen.V398.Message.Message Evergreen.V398.Id.ThreadMessageId (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V398.UserSession.Viewing_DiscordChannelData (Evergreen.V398.UserSession.ToBeFilledInByBackend (Evergreen.V398.UserSession.ViewDiscordGuildData Evergreen.V398.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V398.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V398.UserSession.ToBeFilledInByBackend (Evergreen.V398.UserSession.ViewDiscordGuildData Evergreen.V398.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (Evergreen.V398.UserSession.ToBeFilledInByBackend Evergreen.V398.UserSession.UnreadOverviewData)
