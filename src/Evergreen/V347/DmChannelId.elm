module Evergreen.V347.DmChannelId exposing (..)

import Evergreen.V347.Id


type DmChannelId
    = DmChannelId (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId) (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
