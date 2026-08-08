module Evergreen.V348.DmChannelId exposing (..)

import Evergreen.V348.Id


type DmChannelId
    = DmChannelId (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
