module Evergreen.V298.Sticker exposing (..)

import Evergreen.V298.Coord
import Evergreen.V298.CssPixels
import Evergreen.V298.Discord
import Evergreen.V298.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V298.FileStatus.FileHash (Maybe (Evergreen.V298.Coord.Coord Evergreen.V298.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V298.Discord.Id Evergreen.V298.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V298.Discord.StickerFormatType
    }
