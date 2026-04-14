module Evergreen.V199.Sticker exposing (..)

import Evergreen.V199.Coord
import Evergreen.V199.CssPixels
import Evergreen.V199.Discord
import Evergreen.V199.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V199.FileStatus.FileHash (Maybe (Evergreen.V199.Coord.Coord Evergreen.V199.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V199.Discord.Id Evergreen.V199.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V199.Discord.StickerFormatType
    }
