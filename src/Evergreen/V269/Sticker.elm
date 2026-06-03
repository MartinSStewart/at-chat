module Evergreen.V269.Sticker exposing (..)

import Evergreen.V269.Coord
import Evergreen.V269.CssPixels
import Evergreen.V269.Discord
import Evergreen.V269.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V269.FileStatus.FileHash (Maybe (Evergreen.V269.Coord.Coord Evergreen.V269.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V269.Discord.Id Evergreen.V269.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V269.Discord.StickerFormatType
    }
