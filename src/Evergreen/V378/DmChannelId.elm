module Evergreen.V378.DmChannelId exposing (..)

import Evergreen.V378.Id


type DmChannelId
    = DmChannelId (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
