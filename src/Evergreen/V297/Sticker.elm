module Evergreen.V297.Sticker exposing (..)

import Evergreen.V297.Coord
import Evergreen.V297.CssPixels
import Evergreen.V297.Discord
import Evergreen.V297.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V297.FileStatus.FileHash (Maybe (Evergreen.V297.Coord.Coord Evergreen.V297.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V297.Discord.Id Evergreen.V297.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V297.Discord.StickerFormatType
    }
