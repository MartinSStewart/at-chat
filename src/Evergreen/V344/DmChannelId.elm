module Evergreen.V344.DmChannelId exposing (..)

import Evergreen.V344.Id


type DmChannelId
    = DmChannelId (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
