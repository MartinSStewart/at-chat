module Evergreen.V313.DmChannelId exposing (..)

import Evergreen.V313.Id


type DmChannelId
    = DmChannelId (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
