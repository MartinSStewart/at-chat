module Evergreen.V213.Sticker exposing (..)

import Evergreen.V213.Coord
import Evergreen.V213.CssPixels
import Evergreen.V213.Discord
import Evergreen.V213.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V213.FileStatus.FileHash (Maybe (Evergreen.V213.Coord.Coord Evergreen.V213.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V213.Discord.Id Evergreen.V213.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V213.Discord.StickerFormatType
    }
