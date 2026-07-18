module Evergreen.V328.DmChannelId exposing (..)

import Evergreen.V328.Id


type DmChannelId
    = DmChannelId (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId) (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
