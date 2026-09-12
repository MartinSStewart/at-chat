module Evergreen.V381.DmChannelId exposing (..)

import Evergreen.V381.Id


type DmChannelId
    = DmChannelId (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
