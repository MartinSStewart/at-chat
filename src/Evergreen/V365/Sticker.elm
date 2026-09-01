module Evergreen.V365.Sticker exposing (..)

import Evergreen.V365.Coord
import Evergreen.V365.CssPixels
import Evergreen.V365.Discord
import Evergreen.V365.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V365.FileStatus.FileHash (Maybe (Evergreen.V365.Coord.Coord Evergreen.V365.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V365.Discord.Id Evergreen.V365.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V365.Discord.StickerFormatType
    }
