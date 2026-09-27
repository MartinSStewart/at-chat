module Evergreen.V386.SetViewing exposing (..)

import Evergreen.V386.Discord
import Evergreen.V386.DmChannel
import Evergreen.V386.Id
import Evergreen.V386.Message
import Evergreen.V386.UserSession
import SeqDict


type SetViewing
    = ViewDm Evergreen.V386.UserSession.Viewing_DmData (Evergreen.V386.UserSession.ToBeFilledInByBackend Evergreen.V386.DmChannel.LoadedMessages)
    | ViewDmThread Evergreen.V386.UserSession.Viewing_DmThreadData (Evergreen.V386.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ThreadMessageId) (Evergreen.V386.Message.Message Evergreen.V386.Id.ThreadMessageId (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId))))
    | ViewDiscordDm Evergreen.V386.UserSession.Viewing_DiscordDmData (Evergreen.V386.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.Message.Message Evergreen.V386.Id.ChannelMessageId (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId))))
    | ViewChannel Evergreen.V386.UserSession.Viewing_ChannelData (Evergreen.V386.UserSession.ToBeFilledInByBackend Evergreen.V386.DmChannel.LoadedMessages)
    | ViewChannelThread Evergreen.V386.UserSession.Viewing_ChannelThreadData (Evergreen.V386.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ThreadMessageId) (Evergreen.V386.Message.Message Evergreen.V386.Id.ThreadMessageId (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId))))
    | ViewDiscordChannel Evergreen.V386.UserSession.Viewing_DiscordChannelData (Evergreen.V386.UserSession.ToBeFilledInByBackend (Evergreen.V386.UserSession.ViewDiscordGuildData Evergreen.V386.Id.ChannelMessageId))
    | ViewDiscordChannelThread Evergreen.V386.UserSession.Viewing_DiscordChannelThreadData (Evergreen.V386.UserSession.ToBeFilledInByBackend (Evergreen.V386.UserSession.ViewDiscordGuildData Evergreen.V386.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (Evergreen.V386.UserSession.ToBeFilledInByBackend Evergreen.V386.UserSession.UnreadOverviewData)
