module Evergreen.V392.DmChannelId exposing (..)

import Evergreen.V392.Id


type DmChannelId
    = DmChannelId (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
