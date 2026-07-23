module Evergreen.V334.DmChannelId exposing (..)

import Evergreen.V334.Id


type DmChannelId
    = DmChannelId (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId) (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
