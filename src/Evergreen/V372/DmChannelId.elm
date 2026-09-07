module Evergreen.V372.DmChannelId exposing (..)

import Evergreen.V372.Id


type DmChannelId
    = DmChannelId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
