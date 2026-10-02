module Evergreen.V396.DmChannelId exposing (..)

import Evergreen.V396.Id


type DmChannelId
    = DmChannelId (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
