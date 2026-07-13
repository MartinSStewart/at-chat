module Evergreen.V317.DmChannelId exposing (..)

import Evergreen.V317.Id


type DmChannelId
    = DmChannelId (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
