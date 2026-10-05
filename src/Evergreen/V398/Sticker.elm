module Evergreen.V398.Sticker exposing (..)

import Evergreen.V398.Coord
import Evergreen.V398.CssPixels
import Evergreen.V398.Discord
import Evergreen.V398.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V398.FileStatus.FileHash (Maybe (Evergreen.V398.Coord.Coord Evergreen.V398.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V398.Discord.Id Evergreen.V398.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V398.Discord.StickerFormatType
    }
