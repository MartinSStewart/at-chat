module Evergreen.V386.Sticker exposing (..)

import Evergreen.V386.Coord
import Evergreen.V386.CssPixels
import Evergreen.V386.Discord
import Evergreen.V386.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V386.FileStatus.FileHash (Maybe (Evergreen.V386.Coord.Coord Evergreen.V386.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V386.Discord.Id Evergreen.V386.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V386.Discord.StickerFormatType
    }
