module Evergreen.V315.DmChannelId exposing (..)

import Evergreen.V315.Id


type DmChannelId
    = DmChannelId (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
