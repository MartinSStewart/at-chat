module Evergreen.V378.Sticker exposing (..)

import Evergreen.V378.Coord
import Evergreen.V378.CssPixels
import Evergreen.V378.Discord
import Evergreen.V378.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V378.FileStatus.FileHash (Maybe (Evergreen.V378.Coord.Coord Evergreen.V378.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V378.Discord.Id Evergreen.V378.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V378.Discord.StickerFormatType
    }
