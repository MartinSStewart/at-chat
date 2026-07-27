module Evergreen.V335.Sticker exposing (..)

import Evergreen.V335.Coord
import Evergreen.V335.CssPixels
import Evergreen.V335.Discord
import Evergreen.V335.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V335.FileStatus.FileHash (Maybe (Evergreen.V335.Coord.Coord Evergreen.V335.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V335.Discord.Id Evergreen.V335.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V335.Discord.StickerFormatType
    }
