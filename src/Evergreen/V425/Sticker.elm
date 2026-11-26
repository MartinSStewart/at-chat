module Evergreen.V425.Sticker exposing (..)

import Evergreen.V425.Coord
import Evergreen.V425.CssPixels
import Evergreen.V425.Discord
import Evergreen.V425.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V425.FileStatus.FileHash (Maybe (Evergreen.V425.Coord.Coord Evergreen.V425.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V425.Discord.Id Evergreen.V425.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V425.Discord.StickerFormatType
    }
