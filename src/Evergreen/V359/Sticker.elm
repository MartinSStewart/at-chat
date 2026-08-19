module Evergreen.V359.Sticker exposing (..)

import Evergreen.V359.Coord
import Evergreen.V359.CssPixels
import Evergreen.V359.Discord
import Evergreen.V359.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V359.FileStatus.FileHash (Maybe (Evergreen.V359.Coord.Coord Evergreen.V359.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V359.Discord.Id Evergreen.V359.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V359.Discord.StickerFormatType
    }
