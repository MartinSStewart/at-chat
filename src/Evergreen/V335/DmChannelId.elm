module Evergreen.V335.DmChannelId exposing (..)

import Evergreen.V335.Id


type DmChannelId
    = DmChannelId (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
