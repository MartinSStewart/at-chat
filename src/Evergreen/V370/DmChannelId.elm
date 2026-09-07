module Evergreen.V370.DmChannelId exposing (..)

import Evergreen.V370.Id


type DmChannelId
    = DmChannelId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
