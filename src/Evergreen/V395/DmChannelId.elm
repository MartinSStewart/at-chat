module Evergreen.V395.DmChannelId exposing (..)

import Evergreen.V395.Id


type DmChannelId
    = DmChannelId (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
