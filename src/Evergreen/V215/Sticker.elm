module Evergreen.V215.Sticker exposing (..)

import Evergreen.V215.Coord
import Evergreen.V215.CssPixels
import Evergreen.V215.Discord
import Evergreen.V215.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V215.FileStatus.FileHash (Maybe (Evergreen.V215.Coord.Coord Evergreen.V215.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V215.Discord.Id Evergreen.V215.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V215.Discord.StickerFormatType
    }
