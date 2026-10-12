module Evergreen.V404.Sticker exposing (..)

import Evergreen.V404.Coord
import Evergreen.V404.CssPixels
import Evergreen.V404.Discord
import Evergreen.V404.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V404.FileStatus.FileHash (Maybe (Evergreen.V404.Coord.Coord Evergreen.V404.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V404.Discord.Id Evergreen.V404.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V404.Discord.StickerFormatType
    }
