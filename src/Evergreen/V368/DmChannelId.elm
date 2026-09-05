module Evergreen.V368.DmChannelId exposing (..)

import Evergreen.V368.Id


type DmChannelId
    = DmChannelId (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
