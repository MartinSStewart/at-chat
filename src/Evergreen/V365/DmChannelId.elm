module Evergreen.V365.DmChannelId exposing (..)

import Evergreen.V365.Id


type DmChannelId
    = DmChannelId (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
