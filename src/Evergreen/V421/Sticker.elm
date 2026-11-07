module Evergreen.V421.Sticker exposing (..)

import Evergreen.V421.Coord
import Evergreen.V421.CssPixels
import Evergreen.V421.Discord
import Evergreen.V421.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V421.FileStatus.FileHash (Maybe (Evergreen.V421.Coord.Coord Evergreen.V421.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V421.Discord.Id Evergreen.V421.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V421.Discord.StickerFormatType
    }
