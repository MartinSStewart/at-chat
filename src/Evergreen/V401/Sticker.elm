module Evergreen.V401.Sticker exposing (..)

import Evergreen.V401.Coord
import Evergreen.V401.CssPixels
import Evergreen.V401.Discord
import Evergreen.V401.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V401.FileStatus.FileHash (Maybe (Evergreen.V401.Coord.Coord Evergreen.V401.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V401.Discord.Id Evergreen.V401.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V401.Discord.StickerFormatType
    }
