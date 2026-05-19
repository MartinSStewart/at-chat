module Evergreen.V240.Sticker exposing (..)

import Evergreen.V240.Coord
import Evergreen.V240.CssPixels
import Evergreen.V240.Discord
import Evergreen.V240.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V240.FileStatus.FileHash (Maybe (Evergreen.V240.Coord.Coord Evergreen.V240.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V240.Discord.Id Evergreen.V240.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V240.Discord.StickerFormatType
    }
