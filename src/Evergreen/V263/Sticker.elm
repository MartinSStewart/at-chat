module Evergreen.V263.Sticker exposing (..)

import Evergreen.V263.Coord
import Evergreen.V263.CssPixels
import Evergreen.V263.Discord
import Evergreen.V263.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V263.FileStatus.FileHash (Maybe (Evergreen.V263.Coord.Coord Evergreen.V263.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V263.Discord.Id Evergreen.V263.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V263.Discord.StickerFormatType
    }
