module Evergreen.V389.DmChannelId exposing (..)

import Evergreen.V389.Id


type DmChannelId
    = DmChannelId (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
