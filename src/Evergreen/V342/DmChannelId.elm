module Evergreen.V342.DmChannelId exposing (..)

import Evergreen.V342.Id


type DmChannelId
    = DmChannelId (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
