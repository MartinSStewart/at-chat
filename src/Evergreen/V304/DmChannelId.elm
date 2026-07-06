module Evergreen.V304.DmChannelId exposing (..)

import Evergreen.V304.Id


type DmChannelId
    = DmChannelId (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
