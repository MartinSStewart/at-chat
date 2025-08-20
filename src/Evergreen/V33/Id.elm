module Evergreen.V33.Id exposing (..)


type GuildId
    = GuildId Never


type Id a
    = Id Int


type ChannelId
    = ChannelId Never


type ThreadRoute
    = NoThread
    | ViewThread Int


type InviteLinkId
    = InviteLinkId Never


type UserId
    = UserId Never


type GuildOrDmId
    = GuildOrDmId_Guild (Id GuildId) (Id ChannelId) ThreadRoute
    | GuildOrDmId_Dm (Id UserId) ThreadRoute
