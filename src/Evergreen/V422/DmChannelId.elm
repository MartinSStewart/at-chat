module Evergreen.V422.DmChannelId exposing (..)

import Evergreen.V422.Id


type DmChannelId
    = DmChannelId (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
