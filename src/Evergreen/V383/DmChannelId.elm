module Evergreen.V383.DmChannelId exposing (..)

import Evergreen.V383.Id


type DmChannelId
    = DmChannelId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
