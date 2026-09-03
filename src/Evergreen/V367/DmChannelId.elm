module Evergreen.V367.DmChannelId exposing (..)

import Evergreen.V367.Id


type DmChannelId
    = DmChannelId (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
