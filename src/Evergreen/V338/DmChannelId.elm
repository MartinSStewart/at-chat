module Evergreen.V338.DmChannelId exposing (..)

import Evergreen.V338.Id


type DmChannelId
    = DmChannelId (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
