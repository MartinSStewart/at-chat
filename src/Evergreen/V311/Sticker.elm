module Evergreen.V311.Sticker exposing (..)

import Evergreen.V311.Coord
import Evergreen.V311.CssPixels
import Evergreen.V311.Discord
import Evergreen.V311.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V311.FileStatus.FileHash (Maybe (Evergreen.V311.Coord.Coord Evergreen.V311.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V311.Discord.Id Evergreen.V311.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V311.Discord.StickerFormatType
    }
