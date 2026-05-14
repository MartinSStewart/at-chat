module Evergreen.V218.Sticker exposing (..)

import Evergreen.V218.Coord
import Evergreen.V218.CssPixels
import Evergreen.V218.Discord
import Evergreen.V218.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V218.FileStatus.FileHash (Maybe (Evergreen.V218.Coord.Coord Evergreen.V218.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V218.Discord.Id Evergreen.V218.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V218.Discord.StickerFormatType
    }
