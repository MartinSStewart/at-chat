module Evergreen.V277.Sticker exposing (..)

import Evergreen.V277.Coord
import Evergreen.V277.CssPixels
import Evergreen.V277.Discord
import Evergreen.V277.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V277.FileStatus.FileHash (Maybe (Evergreen.V277.Coord.Coord Evergreen.V277.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V277.Discord.Id Evergreen.V277.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V277.Discord.StickerFormatType
    }
