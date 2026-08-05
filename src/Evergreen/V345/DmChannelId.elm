module Evergreen.V345.DmChannelId exposing (..)

import Evergreen.V345.Id


type DmChannelId
    = DmChannelId (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
