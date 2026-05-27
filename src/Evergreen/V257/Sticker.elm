module Evergreen.V257.Sticker exposing (..)

import Evergreen.V257.Coord
import Evergreen.V257.CssPixels
import Evergreen.V257.Discord
import Evergreen.V257.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V257.FileStatus.FileHash (Maybe (Evergreen.V257.Coord.Coord Evergreen.V257.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V257.Discord.Id Evergreen.V257.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V257.Discord.StickerFormatType
    }
