module Evergreen.V384.DmChannelId exposing (..)

import Evergreen.V384.Id


type DmChannelId
    = DmChannelId (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
