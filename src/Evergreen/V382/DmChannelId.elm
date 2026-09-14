module Evergreen.V382.DmChannelId exposing (..)

import Evergreen.V382.Id


type DmChannelId
    = DmChannelId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
