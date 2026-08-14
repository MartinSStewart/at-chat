module Evergreen.V352.DmChannelId exposing (..)

import Evergreen.V352.Id


type DmChannelId
    = DmChannelId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
