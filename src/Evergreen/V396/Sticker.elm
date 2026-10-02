module Evergreen.V396.Sticker exposing (..)

import Evergreen.V396.Coord
import Evergreen.V396.CssPixels
import Evergreen.V396.Discord
import Evergreen.V396.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V396.FileStatus.FileHash (Maybe (Evergreen.V396.Coord.Coord Evergreen.V396.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V396.Discord.Id Evergreen.V396.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V396.Discord.StickerFormatType
    }
