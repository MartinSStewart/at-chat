module Evergreen.V203.Sticker exposing (..)

import Evergreen.V203.Coord
import Evergreen.V203.CssPixels
import Evergreen.V203.Discord
import Evergreen.V203.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V203.FileStatus.FileHash (Maybe (Evergreen.V203.Coord.Coord Evergreen.V203.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V203.Discord.Id Evergreen.V203.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V203.Discord.StickerFormatType
    }
