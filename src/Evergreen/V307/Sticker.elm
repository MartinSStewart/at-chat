module Evergreen.V307.Sticker exposing (..)

import Evergreen.V307.Coord
import Evergreen.V307.CssPixels
import Evergreen.V307.Discord
import Evergreen.V307.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V307.FileStatus.FileHash (Maybe (Evergreen.V307.Coord.Coord Evergreen.V307.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V307.Discord.Id Evergreen.V307.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V307.Discord.StickerFormatType
    }
