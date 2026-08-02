module Evergreen.V343.DmChannelId exposing (..)

import Evergreen.V343.Id


type DmChannelId
    = DmChannelId (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
