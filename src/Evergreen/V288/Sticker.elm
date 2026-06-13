module Evergreen.V288.Sticker exposing (..)

import Evergreen.V288.Coord
import Evergreen.V288.CssPixels
import Evergreen.V288.Discord
import Evergreen.V288.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V288.FileStatus.FileHash (Maybe (Evergreen.V288.Coord.Coord Evergreen.V288.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V288.Discord.Id Evergreen.V288.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V288.Discord.StickerFormatType
    }
