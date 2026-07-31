module Evergreen.V341.Sticker exposing (..)

import Evergreen.V341.Coord
import Evergreen.V341.CssPixels
import Evergreen.V341.Discord
import Evergreen.V341.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V341.FileStatus.FileHash (Maybe (Evergreen.V341.Coord.Coord Evergreen.V341.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V341.Discord.Id Evergreen.V341.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V341.Discord.StickerFormatType
    }
