module Evergreen.V318.DmChannelId exposing (..)

import Evergreen.V318.Id


type DmChannelId
    = DmChannelId (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
