module Evergreen.V332.DmChannelId exposing (..)

import Evergreen.V332.Id


type DmChannelId
    = DmChannelId (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
