module Evergreen.V408.DmChannelId exposing (..)

import Evergreen.V408.Id


type DmChannelId
    = DmChannelId (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
