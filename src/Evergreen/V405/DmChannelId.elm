module Evergreen.V405.DmChannelId exposing (..)

import Evergreen.V405.Id


type DmChannelId
    = DmChannelId (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
