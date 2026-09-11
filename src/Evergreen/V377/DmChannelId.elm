module Evergreen.V377.DmChannelId exposing (..)

import Evergreen.V377.Id


type DmChannelId
    = DmChannelId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
