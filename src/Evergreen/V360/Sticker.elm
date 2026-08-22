module Evergreen.V360.Sticker exposing (..)

import Evergreen.V360.Coord
import Evergreen.V360.CssPixels
import Evergreen.V360.Discord
import Evergreen.V360.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V360.FileStatus.FileHash (Maybe (Evergreen.V360.Coord.Coord Evergreen.V360.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V360.Discord.Id Evergreen.V360.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V360.Discord.StickerFormatType
    }
