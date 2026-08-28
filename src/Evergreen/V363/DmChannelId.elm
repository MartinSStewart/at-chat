module Evergreen.V363.DmChannelId exposing (..)

import Evergreen.V363.Id


type DmChannelId
    = DmChannelId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
