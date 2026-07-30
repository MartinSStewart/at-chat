module Evergreen.V340.DmChannelId exposing (..)

import Evergreen.V340.Id


type DmChannelId
    = DmChannelId (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
