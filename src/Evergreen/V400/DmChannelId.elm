module Evergreen.V400.DmChannelId exposing (..)

import Evergreen.V400.Id


type DmChannelId
    = DmChannelId (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId) (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
