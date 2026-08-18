module Evergreen.V357.DmChannelId exposing (..)

import Evergreen.V357.Id


type DmChannelId
    = DmChannelId (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
