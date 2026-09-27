module Evergreen.V387.DmChannelId exposing (..)

import Evergreen.V387.Id


type DmChannelId
    = DmChannelId (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
