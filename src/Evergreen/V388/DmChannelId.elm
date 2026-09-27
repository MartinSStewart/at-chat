module Evergreen.V388.DmChannelId exposing (..)

import Evergreen.V388.Id


type DmChannelId
    = DmChannelId (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
