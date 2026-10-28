module Evergreen.V419.DmChannelId exposing (..)

import Evergreen.V419.Id


type DmChannelId
    = DmChannelId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
