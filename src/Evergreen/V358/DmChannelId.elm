module Evergreen.V358.DmChannelId exposing (..)

import Evergreen.V358.Id


type DmChannelId
    = DmChannelId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
