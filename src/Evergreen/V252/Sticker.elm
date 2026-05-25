module Evergreen.V252.Sticker exposing (..)

import Evergreen.V252.Coord
import Evergreen.V252.CssPixels
import Evergreen.V252.Discord
import Evergreen.V252.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V252.FileStatus.FileHash (Maybe (Evergreen.V252.Coord.Coord Evergreen.V252.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V252.Discord.Id Evergreen.V252.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V252.Discord.StickerFormatType
    }
