module Evergreen.V238.Sticker exposing (..)

import Evergreen.V238.Coord
import Evergreen.V238.CssPixels
import Evergreen.V238.Discord
import Evergreen.V238.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V238.FileStatus.FileHash (Maybe (Evergreen.V238.Coord.Coord Evergreen.V238.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V238.Discord.Id Evergreen.V238.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V238.Discord.StickerFormatType
    }
