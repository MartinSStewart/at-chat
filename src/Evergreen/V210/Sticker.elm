module Evergreen.V210.Sticker exposing (..)

import Evergreen.V210.Coord
import Evergreen.V210.CssPixels
import Evergreen.V210.Discord
import Evergreen.V210.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V210.FileStatus.FileHash (Maybe (Evergreen.V210.Coord.Coord Evergreen.V210.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V210.Discord.Id Evergreen.V210.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V210.Discord.StickerFormatType
    }
