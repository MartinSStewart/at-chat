module Evergreen.V309.DmChannelId exposing (..)

import Evergreen.V309.Id


type DmChannelId
    = DmChannelId (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
