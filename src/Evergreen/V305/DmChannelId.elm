module Evergreen.V305.DmChannelId exposing (..)

import Evergreen.V305.Id


type DmChannelId
    = DmChannelId (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V305.Id.Id Evergreen.V305.Id.GuildId) (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
