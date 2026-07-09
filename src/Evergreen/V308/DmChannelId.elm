module Evergreen.V308.DmChannelId exposing (..)

import Evergreen.V308.Id


type DmChannelId
    = DmChannelId (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
