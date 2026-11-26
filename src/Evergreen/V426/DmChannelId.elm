module Evergreen.V426.DmChannelId exposing (..)

import Evergreen.V426.Id


type DmChannelId
    = DmChannelId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
