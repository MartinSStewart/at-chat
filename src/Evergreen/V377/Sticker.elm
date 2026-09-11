module Evergreen.V377.Sticker exposing (..)

import Evergreen.V377.Coord
import Evergreen.V377.CssPixels
import Evergreen.V377.Discord
import Evergreen.V377.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V377.FileStatus.FileHash (Maybe (Evergreen.V377.Coord.Coord Evergreen.V377.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V377.Discord.Id Evergreen.V377.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V377.Discord.StickerFormatType
    }
