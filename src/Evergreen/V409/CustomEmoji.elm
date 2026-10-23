module Evergreen.V409.CustomEmoji exposing (..)

import Evergreen.V409.Coord
import Evergreen.V409.CssPixels
import Evergreen.V409.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V409.FileStatus.FileHash (Maybe (Evergreen.V409.Coord.Coord Evergreen.V409.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
