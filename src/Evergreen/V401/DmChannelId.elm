module Evergreen.V401.DmChannelId exposing (..)

import Evergreen.V401.Id


type DmChannelId
    = DmChannelId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
