module Evergreen.V394.DmChannelId exposing (..)

import Evergreen.V394.Id


type DmChannelId
    = DmChannelId (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
