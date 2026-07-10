module Evergreen.V311.DmChannelId exposing (..)

import Evergreen.V311.Id


type DmChannelId
    = DmChannelId (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
