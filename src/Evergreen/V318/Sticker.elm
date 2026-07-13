module Evergreen.V318.Sticker exposing (..)

import Evergreen.V318.Coord
import Evergreen.V318.CssPixels
import Evergreen.V318.Discord
import Evergreen.V318.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V318.FileStatus.FileHash (Maybe (Evergreen.V318.Coord.Coord Evergreen.V318.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V318.Discord.Id Evergreen.V318.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V318.Discord.StickerFormatType
    }
