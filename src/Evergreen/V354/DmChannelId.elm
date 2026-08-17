module Evergreen.V354.DmChannelId exposing (..)

import Evergreen.V354.Id


type DmChannelId
    = DmChannelId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
