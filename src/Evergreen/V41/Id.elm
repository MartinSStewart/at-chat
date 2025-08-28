module Evergreen.V41.Id exposing (..)


type GuildId
    = GuildId Never


type Id a
    = Id Int


type ChannelId
    = ChannelId Never


type ChannelMessageId
    = ChannelMessageId Never


type ThreadMessageId
    = ThreadMessageId Never


type ThreadRouteWithMaybeMessage
    = NoThreadWithMaybeMessage (Maybe (Id ChannelMessageId))
    | ViewThreadWithMaybeMessage (Id ChannelMessageId) (Maybe (Id ThreadMessageId))


type InviteLinkId
    = InviteLinkId Never


type UserId
    = UserId Never


type GuildOrDmIdNoThread
    = GuildOrDmId_Guild_NoThread (Id GuildId) (Id ChannelId)
    | GuildOrDmId_Dm_NoThread (Id UserId)


type ThreadRoute
    = NoThread
    | ViewThread (Id ChannelMessageId)


type GuildOrDmId
    = GuildOrDmId_Guild (Id GuildId) (Id ChannelId) ThreadRoute
    | GuildOrDmId_Dm (Id UserId) ThreadRoute


type ThreadRouteWithMessage
    = NoThreadWithMessage (Id ChannelMessageId)
    | ViewThreadWithMessage (Id ChannelMessageId) (Id ThreadMessageId)
