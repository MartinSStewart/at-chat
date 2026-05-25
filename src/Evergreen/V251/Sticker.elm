module Evergreen.V251.Sticker exposing (..)

import Evergreen.V251.Coord
import Evergreen.V251.CssPixels
import Evergreen.V251.Discord
import Evergreen.V251.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V251.FileStatus.FileHash (Maybe (Evergreen.V251.Coord.Coord Evergreen.V251.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V251.Discord.Id Evergreen.V251.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V251.Discord.StickerFormatType
    }
