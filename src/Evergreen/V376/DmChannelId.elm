module Evergreen.V376.DmChannelId exposing (..)

import Evergreen.V376.Id


type DmChannelId
    = DmChannelId (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
