module Evergreen.V386.DmChannelId exposing (..)

import Evergreen.V386.Id


type DmChannelId
    = DmChannelId (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
