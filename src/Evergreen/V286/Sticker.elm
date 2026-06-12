module Evergreen.V286.Sticker exposing (..)

import Evergreen.V286.Coord
import Evergreen.V286.CssPixels
import Evergreen.V286.Discord
import Evergreen.V286.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V286.FileStatus.FileHash (Maybe (Evergreen.V286.Coord.Coord Evergreen.V286.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V286.Discord.Id Evergreen.V286.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V286.Discord.StickerFormatType
    }
