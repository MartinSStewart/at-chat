module Evergreen.V385.DmChannelId exposing (..)

import Evergreen.V385.Id


type DmChannelId
    = DmChannelId (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
