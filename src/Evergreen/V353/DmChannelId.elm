module Evergreen.V353.DmChannelId exposing (..)

import Evergreen.V353.Id


type DmChannelId
    = DmChannelId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
