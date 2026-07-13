module Evergreen.V317.Sticker exposing (..)

import Evergreen.V317.Coord
import Evergreen.V317.CssPixels
import Evergreen.V317.Discord
import Evergreen.V317.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V317.FileStatus.FileHash (Maybe (Evergreen.V317.Coord.Coord Evergreen.V317.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V317.Discord.Id Evergreen.V317.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V317.Discord.StickerFormatType
    }
