module Evergreen.V344.Sticker exposing (..)

import Evergreen.V344.Coord
import Evergreen.V344.CssPixels
import Evergreen.V344.Discord
import Evergreen.V344.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V344.FileStatus.FileHash (Maybe (Evergreen.V344.Coord.Coord Evergreen.V344.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V344.Discord.Id Evergreen.V344.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V344.Discord.StickerFormatType
    }
