module Evergreen.V270.Sticker exposing (..)

import Evergreen.V270.Coord
import Evergreen.V270.CssPixels
import Evergreen.V270.Discord
import Evergreen.V270.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V270.FileStatus.FileHash (Maybe (Evergreen.V270.Coord.Coord Evergreen.V270.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V270.Discord.Id Evergreen.V270.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V270.Discord.StickerFormatType
    }
