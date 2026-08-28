module Evergreen.V364.DmChannelId exposing (..)

import Evergreen.V364.Id


type DmChannelId
    = DmChannelId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
