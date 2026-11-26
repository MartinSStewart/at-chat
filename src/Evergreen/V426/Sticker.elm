module Evergreen.V426.Sticker exposing (..)

import Evergreen.V426.Coord
import Evergreen.V426.CssPixels
import Evergreen.V426.Discord
import Evergreen.V426.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V426.FileStatus.FileHash (Maybe (Evergreen.V426.Coord.Coord Evergreen.V426.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V426.Discord.Id Evergreen.V426.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V426.Discord.StickerFormatType
    }
