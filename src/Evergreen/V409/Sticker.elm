module Evergreen.V409.Sticker exposing (..)

import Evergreen.V409.Coord
import Evergreen.V409.CssPixels
import Evergreen.V409.Discord
import Evergreen.V409.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V409.FileStatus.FileHash (Maybe (Evergreen.V409.Coord.Coord Evergreen.V409.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V409.Discord.Id Evergreen.V409.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V409.Discord.StickerFormatType
    }
