module Evergreen.V387.SetViewing exposing (..)

import Evergreen.V387.Discord
import Evergreen.V387.DmChannel
import Evergreen.V387.Id
import Evergreen.V387.Message
import Evergreen.V387.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V387.UserSession.Viewing_DmData (Evergreen.V387.UserSession.ToBeFilledInByBackend Evergreen.V387.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V387.UserSession.Viewing_DmThreadData (Evergreen.V387.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ThreadMessageId) (Evergreen.V387.Message.Message Evergreen.V387.Id.ThreadMessageId (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V387.UserSession.Viewing_DiscordDmData (Evergreen.V387.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.Message.Message Evergreen.V387.Id.ChannelMessageId (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId))))
    | ViewChannel Evergreen.V387.UserSession.Viewing_ChannelData (Evergreen.V387.UserSession.ToBeFilledInByBackend Evergreen.V387.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V387.UserSession.Viewing_ChannelThreadData (Evergreen.V387.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ThreadMessageId) (Evergreen.V387.Message.Message Evergreen.V387.Id.ThreadMessageId (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V387.UserSession.Viewing_DiscordChannelData (Evergreen.V387.UserSession.ToBeFilledInByBackend (Evergreen.V387.UserSession.ViewDiscordGuildData Evergreen.V387.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V387.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V387.UserSession.ToBeFilledInByBackend (Evergreen.V387.UserSession.ViewDiscordGuildData Evergreen.V387.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (Evergreen.V387.UserSession.ToBeFilledInByBackend Evergreen.V387.UserSession.UnreadOverviewData)
