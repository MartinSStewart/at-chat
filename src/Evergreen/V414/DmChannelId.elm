module Evergreen.V414.DmChannelId exposing (..)

import Evergreen.V414.Id


type DmChannelId
    = DmChannelId (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId) (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
