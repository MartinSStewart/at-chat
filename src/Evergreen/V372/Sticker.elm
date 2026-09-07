module Evergreen.V372.Sticker exposing (..)

import Evergreen.V372.Coord
import Evergreen.V372.CssPixels
import Evergreen.V372.Discord
import Evergreen.V372.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V372.FileStatus.FileHash (Maybe (Evergreen.V372.Coord.Coord Evergreen.V372.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V372.Discord.Id Evergreen.V372.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V372.Discord.StickerFormatType
    }
