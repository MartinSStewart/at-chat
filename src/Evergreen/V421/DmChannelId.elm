module Evergreen.V421.DmChannelId exposing (..)

import Evergreen.V421.Id


type DmChannelId
    = DmChannelId (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
