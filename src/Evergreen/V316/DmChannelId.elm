module Evergreen.V316.DmChannelId exposing (..)

import Evergreen.V316.Id


type DmChannelId
    = DmChannelId (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
