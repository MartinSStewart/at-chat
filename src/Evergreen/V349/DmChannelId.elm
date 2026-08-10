module Evergreen.V349.DmChannelId exposing (..)

import Evergreen.V349.Id


type DmChannelId
    = DmChannelId (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
