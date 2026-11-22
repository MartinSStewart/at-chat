module Evergreen.V423.DmChannelId exposing (..)

import Evergreen.V423.Id


type DmChannelId
    = DmChannelId (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
