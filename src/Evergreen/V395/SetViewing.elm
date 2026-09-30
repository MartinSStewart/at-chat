module Evergreen.V395.SetViewing exposing (..)

import Evergreen.V395.Discord
import Evergreen.V395.DmChannel
import Evergreen.V395.Id
import Evergreen.V395.Message
import Evergreen.V395.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V395.UserSession.Viewing_DmData (Evergreen.V395.UserSession.ToBeFilledInByBackend Evergreen.V395.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V395.UserSession.Viewing_DmThreadData (Evergreen.V395.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ThreadMessageId) (Evergreen.V395.Message.Message Evergreen.V395.Id.ThreadMessageId (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V395.UserSession.Viewing_DiscordDmData (Evergreen.V395.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.Message.Message Evergreen.V395.Id.ChannelMessageId (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId))))
    | ViewChannel Evergreen.V395.UserSession.Viewing_ChannelData (Evergreen.V395.UserSession.ToBeFilledInByBackend Evergreen.V395.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V395.UserSession.Viewing_ChannelThreadData (Evergreen.V395.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ThreadMessageId) (Evergreen.V395.Message.Message Evergreen.V395.Id.ThreadMessageId (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V395.UserSession.Viewing_DiscordChannelData (Evergreen.V395.UserSession.ToBeFilledInByBackend (Evergreen.V395.UserSession.ViewDiscordGuildData Evergreen.V395.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V395.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V395.UserSession.ToBeFilledInByBackend (Evergreen.V395.UserSession.ViewDiscordGuildData Evergreen.V395.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (Evergreen.V395.UserSession.ToBeFilledInByBackend Evergreen.V395.UserSession.UnreadOverviewData)
