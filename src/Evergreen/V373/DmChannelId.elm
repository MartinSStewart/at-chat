module Evergreen.V373.DmChannelId exposing (..)

import Evergreen.V373.Id


type DmChannelId
    = DmChannelId (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
