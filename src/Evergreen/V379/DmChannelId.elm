module Evergreen.V379.DmChannelId exposing (..)

import Evergreen.V379.Id


type DmChannelId
    = DmChannelId (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
