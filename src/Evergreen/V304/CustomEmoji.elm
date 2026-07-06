module Evergreen.V304.CustomEmoji exposing (..)

import Evergreen.V304.Coord
import Evergreen.V304.CssPixels
import Evergreen.V304.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V304.FileStatus.FileHash (Maybe (Evergreen.V304.Coord.Coord Evergreen.V304.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
