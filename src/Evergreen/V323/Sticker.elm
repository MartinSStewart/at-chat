module Evergreen.V323.Sticker exposing (..)

import Evergreen.V323.Coord
import Evergreen.V323.CssPixels
import Evergreen.V323.Discord
import Evergreen.V323.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V323.FileStatus.FileHash (Maybe (Evergreen.V323.Coord.Coord Evergreen.V323.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V323.Discord.Id Evergreen.V323.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V323.Discord.StickerFormatType
    }
