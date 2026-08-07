module Evergreen.V346.DmChannelId exposing (..)

import Evergreen.V346.Id


type DmChannelId
    = DmChannelId (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
