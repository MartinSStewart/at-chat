module Evergreen.V279.Sticker exposing (..)

import Evergreen.V279.Coord
import Evergreen.V279.CssPixels
import Evergreen.V279.Discord
import Evergreen.V279.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V279.FileStatus.FileHash (Maybe (Evergreen.V279.Coord.Coord Evergreen.V279.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V279.Discord.Id Evergreen.V279.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V279.Discord.StickerFormatType
    }
