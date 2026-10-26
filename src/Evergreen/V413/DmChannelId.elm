module Evergreen.V413.DmChannelId exposing (..)

import Evergreen.V413.Id


type DmChannelId
    = DmChannelId (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId)
    | GuildOrFullDmId_Dm DmChannelId
