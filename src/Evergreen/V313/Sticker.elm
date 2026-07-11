module Evergreen.V313.Sticker exposing (..)

import Evergreen.V313.Coord
import Evergreen.V313.CssPixels
import Evergreen.V313.Discord
import Evergreen.V313.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V313.FileStatus.FileHash (Maybe (Evergreen.V313.Coord.Coord Evergreen.V313.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V313.Discord.Id Evergreen.V313.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V313.Discord.StickerFormatType
    }
