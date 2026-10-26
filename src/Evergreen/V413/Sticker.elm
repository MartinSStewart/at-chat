module Evergreen.V413.Sticker exposing (..)

import Evergreen.V413.Coord
import Evergreen.V413.CssPixels
import Evergreen.V413.Discord
import Evergreen.V413.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V413.FileStatus.FileHash (Maybe (Evergreen.V413.Coord.Coord Evergreen.V413.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V413.Discord.Id Evergreen.V413.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V413.Discord.StickerFormatType
    }
