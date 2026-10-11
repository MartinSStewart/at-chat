module Evergreen.V403.Sticker exposing (..)

import Evergreen.V403.Coord
import Evergreen.V403.CssPixels
import Evergreen.V403.Discord
import Evergreen.V403.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V403.FileStatus.FileHash (Maybe (Evergreen.V403.Coord.Coord Evergreen.V403.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V403.Discord.Id Evergreen.V403.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V403.Discord.StickerFormatType
    }
