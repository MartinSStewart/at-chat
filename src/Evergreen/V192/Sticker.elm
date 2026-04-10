module Evergreen.V192.Sticker exposing (..)

import Evergreen.V192.Coord
import Evergreen.V192.CssPixels
import Evergreen.V192.Discord
import Evergreen.V192.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V192.FileStatus.FileHash (Maybe (Evergreen.V192.Coord.Coord Evergreen.V192.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V192.Discord.Id Evergreen.V192.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V192.Discord.StickerFormatType
    }
