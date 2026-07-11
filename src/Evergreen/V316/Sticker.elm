module Evergreen.V316.Sticker exposing (..)

import Evergreen.V316.Coord
import Evergreen.V316.CssPixels
import Evergreen.V316.Discord
import Evergreen.V316.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V316.FileStatus.FileHash (Maybe (Evergreen.V316.Coord.Coord Evergreen.V316.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V316.Discord.Id Evergreen.V316.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V316.Discord.StickerFormatType
    }
