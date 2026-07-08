module Evergreen.V307.DmChannelId exposing (..)

import Evergreen.V307.Id


type DmChannelId
    = DmChannelId (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
