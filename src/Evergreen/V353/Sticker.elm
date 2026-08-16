module Evergreen.V353.Sticker exposing (..)

import Evergreen.V353.Coord
import Evergreen.V353.CssPixels
import Evergreen.V353.Discord
import Evergreen.V353.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V353.FileStatus.FileHash (Maybe (Evergreen.V353.Coord.Coord Evergreen.V353.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V353.Discord.Id Evergreen.V353.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V353.Discord.StickerFormatType
    }
