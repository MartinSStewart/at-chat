module Evergreen.V214.Sticker exposing (..)

import Evergreen.V214.Coord
import Evergreen.V214.CssPixels
import Evergreen.V214.Discord
import Evergreen.V214.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V214.FileStatus.FileHash (Maybe (Evergreen.V214.Coord.Coord Evergreen.V214.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V214.Discord.Id Evergreen.V214.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V214.Discord.StickerFormatType
    }
