module Evergreen.V46.Id exposing (..)


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


type alias GuildOrDmId =
    ( GuildOrDmIdNoThread, ThreadRoute )


type ThreadRouteWithMessage
    = NoThreadWithMessage (Id ChannelMessageId)
    | ViewThreadWithMessage (Id ChannelMessageId) (Id ThreadMessageId)
