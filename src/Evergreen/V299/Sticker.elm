module Evergreen.V299.Sticker exposing (..)

import Evergreen.V299.Coord
import Evergreen.V299.CssPixels
import Evergreen.V299.Discord
import Evergreen.V299.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V299.FileStatus.FileHash (Maybe (Evergreen.V299.Coord.Coord Evergreen.V299.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V299.Discord.Id Evergreen.V299.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V299.Discord.StickerFormatType
    }
