module Evergreen.V336.DmChannelId exposing (..)

import Evergreen.V336.Id


type DmChannelId
    = DmChannelId (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
