module Evergreen.V243.Sticker exposing (..)

import Evergreen.V243.Coord
import Evergreen.V243.CssPixels
import Evergreen.V243.Discord
import Evergreen.V243.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V243.FileStatus.FileHash (Maybe (Evergreen.V243.Coord.Coord Evergreen.V243.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V243.Discord.Id Evergreen.V243.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V243.Discord.StickerFormatType
    }
