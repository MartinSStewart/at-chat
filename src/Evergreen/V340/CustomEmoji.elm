module Evergreen.V340.CustomEmoji exposing (..)

import Evergreen.V340.Coord
import Evergreen.V340.CssPixels
import Evergreen.V340.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V340.FileStatus.FileHash (Maybe (Evergreen.V340.Coord.Coord Evergreen.V340.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
