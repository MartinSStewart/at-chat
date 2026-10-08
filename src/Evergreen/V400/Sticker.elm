module Evergreen.V400.Sticker exposing (..)

import Evergreen.V400.Coord
import Evergreen.V400.CssPixels
import Evergreen.V400.Discord
import Evergreen.V400.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V400.FileStatus.FileHash (Maybe (Evergreen.V400.Coord.Coord Evergreen.V400.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V400.Discord.Id Evergreen.V400.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V400.Discord.StickerFormatType
    }
