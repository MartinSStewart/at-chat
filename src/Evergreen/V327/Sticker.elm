module Evergreen.V327.Sticker exposing (..)

import Evergreen.V327.Coord
import Evergreen.V327.CssPixels
import Evergreen.V327.Discord
import Evergreen.V327.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V327.FileStatus.FileHash (Maybe (Evergreen.V327.Coord.Coord Evergreen.V327.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V327.Discord.Id Evergreen.V327.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V327.Discord.StickerFormatType
    }
