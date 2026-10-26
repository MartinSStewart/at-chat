module Evergreen.V412.DmChannelId exposing (..)

import Evergreen.V412.Id


type DmChannelId
    = DmChannelId (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
