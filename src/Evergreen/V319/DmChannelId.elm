module Evergreen.V319.DmChannelId exposing (..)

import Evergreen.V319.Id


type DmChannelId
    = DmChannelId (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
