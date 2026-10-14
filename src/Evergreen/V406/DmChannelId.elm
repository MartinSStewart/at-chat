module Evergreen.V406.DmChannelId exposing (..)

import Evergreen.V406.Id


type DmChannelId
    = DmChannelId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
