module Evergreen.V401.SetViewing exposing (..)

import Evergreen.V401.Discord
import Evergreen.V401.DmChannel
import Evergreen.V401.Id
import Evergreen.V401.Message
import Evergreen.V401.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V401.UserSession.Viewing_DmData (Evergreen.V401.UserSession.ToBeFilledInByBackend Evergreen.V401.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V401.UserSession.Viewing_DmThreadData (Evergreen.V401.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ThreadMessageId) (Evergreen.V401.Message.Message Evergreen.V401.Id.ThreadMessageId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V401.UserSession.Viewing_DiscordDmData (Evergreen.V401.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.Message.Message Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId))))
    | ViewChannel Evergreen.V401.UserSession.Viewing_ChannelData (Evergreen.V401.UserSession.ToBeFilledInByBackend Evergreen.V401.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V401.UserSession.Viewing_ChannelThreadData (Evergreen.V401.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ThreadMessageId) (Evergreen.V401.Message.Message Evergreen.V401.Id.ThreadMessageId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V401.UserSession.Viewing_DiscordChannelData (Evergreen.V401.UserSession.ToBeFilledInByBackend (Evergreen.V401.UserSession.ViewDiscordGuildData Evergreen.V401.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V401.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V401.UserSession.ToBeFilledInByBackend (Evergreen.V401.UserSession.ViewDiscordGuildData Evergreen.V401.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (Evergreen.V401.UserSession.ToBeFilledInByBackend Evergreen.V401.UserSession.UnreadOverviewData)
