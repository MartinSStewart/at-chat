module Evergreen.V359.DmChannelId exposing (..)

import Evergreen.V359.Id


type DmChannelId
    = DmChannelId (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
