module Evergreen.V397.DmChannelId exposing (..)

import Evergreen.V397.Id


type DmChannelId
    = DmChannelId (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
