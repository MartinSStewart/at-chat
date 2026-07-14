module Evergreen.V323.DmChannelId exposing (..)

import Evergreen.V323.Id


type DmChannelId
    = DmChannelId (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
