module Evergreen.V330.DmChannelId exposing (..)

import Evergreen.V330.Id


type DmChannelId
    = DmChannelId (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
