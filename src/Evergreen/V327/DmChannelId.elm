module Evergreen.V327.DmChannelId exposing (..)

import Evergreen.V327.Id


type DmChannelId
    = DmChannelId (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
