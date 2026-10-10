module Evergreen.V402.DmChannelId exposing (..)

import Evergreen.V402.Id


type DmChannelId
    = DmChannelId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
