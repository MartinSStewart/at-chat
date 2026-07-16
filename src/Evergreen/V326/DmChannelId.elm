module Evergreen.V326.DmChannelId exposing (..)

import Evergreen.V326.Id


type DmChannelId
    = DmChannelId (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
