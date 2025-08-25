module Evergreen.V31.Id exposing (..)


type GuildId
    = GuildId Never


type Id a
    = Id Int


type ChannelId
    = ChannelId Never


type InviteLinkId
    = InviteLinkId Never


type UserId
    = UserId Never


type GuildOrDmId
    = GuildOrDmId_Guild (Id GuildId) (Id ChannelId)
    | GuildOrDmId_Dm (Id UserId)
