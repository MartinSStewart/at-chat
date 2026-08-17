module Evergreen.V354.Sticker exposing (..)

import Evergreen.V354.Coord
import Evergreen.V354.CssPixels
import Evergreen.V354.Discord
import Evergreen.V354.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V354.FileStatus.FileHash (Maybe (Evergreen.V354.Coord.Coord Evergreen.V354.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V354.Discord.Id Evergreen.V354.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V354.Discord.StickerFormatType
    }
