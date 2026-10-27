module Evergreen.V417.DmChannelId exposing (..)

import Evergreen.V417.Id


type DmChannelId
    = DmChannelId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
