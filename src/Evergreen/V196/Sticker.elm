module Evergreen.V196.Sticker exposing (..)

import Evergreen.V196.Coord
import Evergreen.V196.CssPixels
import Evergreen.V196.Discord
import Evergreen.V196.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V196.FileStatus.FileHash (Maybe (Evergreen.V196.Coord.Coord Evergreen.V196.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V196.Discord.Id Evergreen.V196.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V196.Discord.StickerFormatType
    }
