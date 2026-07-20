module Evergreen.V332.Sticker exposing (..)

import Evergreen.V332.Coord
import Evergreen.V332.CssPixels
import Evergreen.V332.Discord
import Evergreen.V332.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V332.FileStatus.FileHash (Maybe (Evergreen.V332.Coord.Coord Evergreen.V332.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V332.Discord.Id Evergreen.V332.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V332.Discord.StickerFormatType
    }
