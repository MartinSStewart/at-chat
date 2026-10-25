module Evergreen.V411.Sticker exposing (..)

import Evergreen.V411.Coord
import Evergreen.V411.CssPixels
import Evergreen.V411.Discord
import Evergreen.V411.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V411.FileStatus.FileHash (Maybe (Evergreen.V411.Coord.Coord Evergreen.V411.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V411.Discord.Id Evergreen.V411.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V411.Discord.StickerFormatType
    }
