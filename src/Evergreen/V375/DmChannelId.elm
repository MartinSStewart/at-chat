module Evergreen.V375.DmChannelId exposing (..)

import Evergreen.V375.Id


type DmChannelId
    = DmChannelId (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
