module Evergreen.V360.DmChannelId exposing (..)

import Evergreen.V360.Id


type DmChannelId
    = DmChannelId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
