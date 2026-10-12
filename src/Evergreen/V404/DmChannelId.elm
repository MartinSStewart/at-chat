module Evergreen.V404.DmChannelId exposing (..)

import Evergreen.V404.Id


type DmChannelId
    = DmChannelId (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId) (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
