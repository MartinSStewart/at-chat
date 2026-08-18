module Evergreen.V357.Sticker exposing (..)

import Evergreen.V357.Coord
import Evergreen.V357.CssPixels
import Evergreen.V357.Discord
import Evergreen.V357.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V357.FileStatus.FileHash (Maybe (Evergreen.V357.Coord.Coord Evergreen.V357.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V357.Discord.Id Evergreen.V357.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V357.Discord.StickerFormatType
    }
