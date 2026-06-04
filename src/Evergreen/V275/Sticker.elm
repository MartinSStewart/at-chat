module Evergreen.V275.Sticker exposing (..)

import Evergreen.V275.Coord
import Evergreen.V275.CssPixels
import Evergreen.V275.Discord
import Evergreen.V275.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V275.FileStatus.FileHash (Maybe (Evergreen.V275.Coord.Coord Evergreen.V275.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V275.Discord.Id Evergreen.V275.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V275.Discord.StickerFormatType
    }
