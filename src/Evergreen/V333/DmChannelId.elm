module Evergreen.V333.DmChannelId exposing (..)

import Evergreen.V333.Id


type DmChannelId
    = DmChannelId (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
