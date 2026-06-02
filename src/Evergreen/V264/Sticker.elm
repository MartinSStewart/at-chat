module Evergreen.V264.Sticker exposing (..)

import Evergreen.V264.Coord
import Evergreen.V264.CssPixels
import Evergreen.V264.Discord
import Evergreen.V264.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V264.FileStatus.FileHash (Maybe (Evergreen.V264.Coord.Coord Evergreen.V264.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V264.Discord.Id Evergreen.V264.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V264.Discord.StickerFormatType
    }
