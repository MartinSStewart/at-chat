module Evergreen.V348.Sticker exposing (..)

import Evergreen.V348.Coord
import Evergreen.V348.CssPixels
import Evergreen.V348.Discord
import Evergreen.V348.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V348.FileStatus.FileHash (Maybe (Evergreen.V348.Coord.Coord Evergreen.V348.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V348.Discord.Id Evergreen.V348.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V348.Discord.StickerFormatType
    }
