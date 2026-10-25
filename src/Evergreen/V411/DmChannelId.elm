module Evergreen.V411.DmChannelId exposing (..)

import Evergreen.V411.Id


type DmChannelId
    = DmChannelId (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId) (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
