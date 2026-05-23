module Evergreen.V248.CustomEmoji exposing (..)

import Evergreen.V248.Coord
import Evergreen.V248.CssPixels
import Evergreen.V248.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V248.FileStatus.FileHash (Maybe (Evergreen.V248.Coord.Coord Evergreen.V248.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
