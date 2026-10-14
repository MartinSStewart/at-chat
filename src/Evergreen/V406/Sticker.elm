module Evergreen.V406.Sticker exposing (..)

import Evergreen.V406.Coord
import Evergreen.V406.CssPixels
import Evergreen.V406.Discord
import Evergreen.V406.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V406.FileStatus.FileHash (Maybe (Evergreen.V406.Coord.Coord Evergreen.V406.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V406.Discord.Id Evergreen.V406.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V406.Discord.StickerFormatType
    }
