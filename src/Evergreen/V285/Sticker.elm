module Evergreen.V285.Sticker exposing (..)

import Evergreen.V285.Coord
import Evergreen.V285.CssPixels
import Evergreen.V285.Discord
import Evergreen.V285.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V285.FileStatus.FileHash (Maybe (Evergreen.V285.Coord.Coord Evergreen.V285.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V285.Discord.Id Evergreen.V285.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V285.Discord.StickerFormatType
    }
