module Evergreen.V381.Sticker exposing (..)

import Evergreen.V381.Coord
import Evergreen.V381.CssPixels
import Evergreen.V381.Discord
import Evergreen.V381.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V381.FileStatus.FileHash (Maybe (Evergreen.V381.Coord.Coord Evergreen.V381.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V381.Discord.Id Evergreen.V381.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V381.Discord.StickerFormatType
    }
