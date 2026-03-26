module Evergreen.V171.Id exposing (..)

import Evergreen.V171.Discord


type Id a
    = Id Int


type GuildId
    = GuildId Never


type ChannelId
    = ChannelId Never


type ChannelMessageId
    = ChannelMessageId Never


type ThreadMessageId
    = ThreadMessageId Never


type InviteLinkId
    = InviteLinkId Never


type UserId
    = UserId Never


type GuildOrDmId
    = GuildOrDmId_Guild (Id GuildId) (Id ChannelId)
    | GuildOrDmId_Dm (Id UserId)


type alias DiscordGuildOrDmId_DmData =
    { currentUserId : Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId
    , channelId : Evergreen.V171.Discord.Id Evergreen.V171.Discord.PrivateChannelId
    }


type DiscordGuildOrDmId
    = DiscordGuildOrDmId_Guild (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.ChannelId)
    | DiscordGuildOrDmId_Dm DiscordGuildOrDmId_DmData


type AnyGuildOrDmId
    = GuildOrDmId GuildOrDmId
    | DiscordGuildOrDmId DiscordGuildOrDmId


type ThreadRoute
    = NoThread
    | ViewThread (Id ChannelMessageId)


type ThreadRouteWithMessage
    = NoThreadWithMessage (Id ChannelMessageId)
    | ViewThreadWithMessage (Id ChannelMessageId) (Id ThreadMessageId)


type ThreadRouteWithMaybeMessage
    = NoThreadWithMaybeMessage (Maybe (Id ChannelMessageId))
    | ViewThreadWithMaybeMessage (Id ChannelMessageId) (Maybe (Id ThreadMessageId))
