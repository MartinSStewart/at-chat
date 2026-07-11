module Evergreen.V312.DmChannelId exposing (..)

import Evergreen.V312.Id


type DmChannelId
    = DmChannelId (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
