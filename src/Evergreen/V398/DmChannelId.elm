module Evergreen.V398.DmChannelId exposing (..)

import Evergreen.V398.Id


type DmChannelId
    = DmChannelId (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
