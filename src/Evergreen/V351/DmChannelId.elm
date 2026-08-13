module Evergreen.V351.DmChannelId exposing (..)

import Evergreen.V351.Id


type DmChannelId
    = DmChannelId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
