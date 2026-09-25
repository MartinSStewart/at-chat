module SetViewing exposing
    ( SetViewing(..)
    , setViewingToCurrentlyViewing
    )

import Discord
import DmChannel
import Id exposing (ChannelId, ChannelMessageId, Id, ThreadMessageId, UserId)
import Message exposing (Message)
import SeqDict exposing (SeqDict)
import UserSession exposing (ToBeFilledInByBackend, UnreadOverviewData, ViewDiscordGuildData, Viewing(..), Viewing_ChannelData, Viewing_ChannelThreadData, Viewing_DiscordChannelData, Viewing_DiscordChannelThreadData, Viewing_DiscordDmData, Viewing_DmData, Viewing_DmThreadData)


type SetViewing
    = ViewDm Viewing_DmData (ToBeFilledInByBackend DmChannel.LoadedMessages)
    | ViewDmThread Viewing_DmThreadData (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Id UserId) (Id ChannelId))))
    | ViewDiscordDm Viewing_DiscordDmData (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Discord.Id Discord.UserId) (Discord.Id Discord.ChannelId))))
    | ViewChannel Viewing_ChannelData (ToBeFilledInByBackend DmChannel.LoadedMessages)
    | ViewChannelThread Viewing_ChannelThreadData (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Id UserId) (Id ChannelId))))
    | ViewDiscordChannel Viewing_DiscordChannelData (ToBeFilledInByBackend (ViewDiscordGuildData ChannelMessageId))
    | ViewDiscordChannelThread Viewing_DiscordChannelThreadData (ToBeFilledInByBackend (ViewDiscordGuildData ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)


setViewingToCurrentlyViewing : SetViewing -> Viewing
setViewingToCurrentlyViewing viewing =
    case viewing of
        ViewDm data _ ->
            Viewing_Dm data

        ViewDmThread data _ ->
            Viewing_DmThread data

        ViewDiscordDm data _ ->
            Viewing_DiscordDm data

        ViewChannel data _ ->
            Viewing_Channel data

        ViewChannelThread data _ ->
            Viewing_ChannelThread data

        ViewDiscordChannel data _ ->
            Viewing_DiscordChannel data

        ViewDiscordChannelThread data _ ->
            Viewing_DiscordChannelThread data

        StopViewingChannel ->
            Viewing_None

        ViewOverview _ ->
            Viewing_Overview
