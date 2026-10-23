module Evergreen.V409.DmChannelId exposing (..)

import Evergreen.V409.Id


type DmChannelId
    = DmChannelId (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
