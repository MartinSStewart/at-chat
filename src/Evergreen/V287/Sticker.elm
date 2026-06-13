module Evergreen.V287.Sticker exposing (..)

import Evergreen.V287.Coord
import Evergreen.V287.CssPixels
import Evergreen.V287.Discord
import Evergreen.V287.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V287.FileStatus.FileHash (Maybe (Evergreen.V287.Coord.Coord Evergreen.V287.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V287.Discord.Id Evergreen.V287.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V287.Discord.StickerFormatType
    }
