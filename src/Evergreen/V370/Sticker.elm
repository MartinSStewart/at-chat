module Evergreen.V370.Sticker exposing (..)

import Evergreen.V370.Coord
import Evergreen.V370.CssPixels
import Evergreen.V370.Discord
import Evergreen.V370.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V370.FileStatus.FileHash (Maybe (Evergreen.V370.Coord.Coord Evergreen.V370.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V370.Discord.Id Evergreen.V370.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V370.Discord.StickerFormatType
    }
