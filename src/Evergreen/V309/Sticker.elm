module Evergreen.V309.Sticker exposing (..)

import Evergreen.V309.Coord
import Evergreen.V309.CssPixels
import Evergreen.V309.Discord
import Evergreen.V309.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V309.FileStatus.FileHash (Maybe (Evergreen.V309.Coord.Coord Evergreen.V309.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V309.Discord.Id Evergreen.V309.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V309.Discord.StickerFormatType
    }
