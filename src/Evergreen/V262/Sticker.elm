module Evergreen.V262.Sticker exposing (..)

import Evergreen.V262.Coord
import Evergreen.V262.CssPixels
import Evergreen.V262.Discord
import Evergreen.V262.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V262.FileStatus.FileHash (Maybe (Evergreen.V262.Coord.Coord Evergreen.V262.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V262.Discord.Id Evergreen.V262.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V262.Discord.StickerFormatType
    }
