module Evergreen.V403.DmChannelId exposing (..)

import Evergreen.V403.Id


type DmChannelId
    = DmChannelId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
