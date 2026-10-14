module Evergreen.V407.DmChannelId exposing (..)

import Evergreen.V407.Id


type DmChannelId
    = DmChannelId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
