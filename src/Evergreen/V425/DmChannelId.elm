module Evergreen.V425.DmChannelId exposing (..)

import Evergreen.V425.Id


type DmChannelId
    = DmChannelId (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
