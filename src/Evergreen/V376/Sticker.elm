module Evergreen.V376.Sticker exposing (..)

import Evergreen.V376.Coord
import Evergreen.V376.CssPixels
import Evergreen.V376.Discord
import Evergreen.V376.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V376.FileStatus.FileHash (Maybe (Evergreen.V376.Coord.Coord Evergreen.V376.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V376.Discord.Id Evergreen.V376.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V376.Discord.StickerFormatType
    }
