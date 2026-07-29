module Evergreen.V339.Sticker exposing (..)

import Evergreen.V339.Coord
import Evergreen.V339.CssPixels
import Evergreen.V339.Discord
import Evergreen.V339.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V339.FileStatus.FileHash (Maybe (Evergreen.V339.Coord.Coord Evergreen.V339.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V339.Discord.Id Evergreen.V339.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V339.Discord.StickerFormatType
    }
