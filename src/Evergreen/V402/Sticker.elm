module Evergreen.V402.Sticker exposing (..)

import Evergreen.V402.Coord
import Evergreen.V402.CssPixels
import Evergreen.V402.Discord
import Evergreen.V402.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V402.FileStatus.FileHash (Maybe (Evergreen.V402.Coord.Coord Evergreen.V402.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V402.Discord.Id Evergreen.V402.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V402.Discord.StickerFormatType
    }
