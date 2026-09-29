module Evergreen.V392.Sticker exposing (..)

import Evergreen.V392.Coord
import Evergreen.V392.CssPixels
import Evergreen.V392.Discord
import Evergreen.V392.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V392.FileStatus.FileHash (Maybe (Evergreen.V392.Coord.Coord Evergreen.V392.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V392.Discord.Id Evergreen.V392.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V392.Discord.StickerFormatType
    }
