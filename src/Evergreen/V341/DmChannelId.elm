module Evergreen.V341.DmChannelId exposing (..)

import Evergreen.V341.Id


type DmChannelId
    = DmChannelId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
