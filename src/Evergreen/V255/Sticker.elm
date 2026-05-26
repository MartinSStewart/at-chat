module Evergreen.V255.Sticker exposing (..)

import Evergreen.V255.Coord
import Evergreen.V255.CssPixels
import Evergreen.V255.Discord
import Evergreen.V255.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V255.FileStatus.FileHash (Maybe (Evergreen.V255.Coord.Coord Evergreen.V255.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V255.Discord.Id Evergreen.V255.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V255.Discord.StickerFormatType
    }
