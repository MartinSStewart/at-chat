module Evergreen.V204.Sticker exposing (..)

import Evergreen.V204.Coord
import Evergreen.V204.CssPixels
import Evergreen.V204.Discord
import Evergreen.V204.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V204.FileStatus.FileHash (Maybe (Evergreen.V204.Coord.Coord Evergreen.V204.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V204.Discord.Id Evergreen.V204.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V204.Discord.StickerFormatType
    }
