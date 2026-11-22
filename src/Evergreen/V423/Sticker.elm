module Evergreen.V423.Sticker exposing (..)

import Evergreen.V423.Coord
import Evergreen.V423.CssPixels
import Evergreen.V423.Discord
import Evergreen.V423.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V423.FileStatus.FileHash (Maybe (Evergreen.V423.Coord.Coord Evergreen.V423.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V423.Discord.Id Evergreen.V423.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V423.Discord.StickerFormatType
    }
