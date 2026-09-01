module Evergreen.V366.DmChannelId exposing (..)

import Evergreen.V366.Id


type DmChannelId
    = DmChannelId (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
