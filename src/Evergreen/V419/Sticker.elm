module Evergreen.V419.Sticker exposing (..)

import Evergreen.V419.Coord
import Evergreen.V419.CssPixels
import Evergreen.V419.Discord
import Evergreen.V419.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V419.FileStatus.FileHash (Maybe (Evergreen.V419.Coord.Coord Evergreen.V419.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V419.Discord.Id Evergreen.V419.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V419.Discord.StickerFormatType
    }
