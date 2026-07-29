module Evergreen.V339.DmChannelId exposing (..)

import Evergreen.V339.Id


type DmChannelId
    = DmChannelId (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
