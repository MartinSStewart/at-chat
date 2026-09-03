module Evergreen.V367.CustomEmoji exposing (..)

import Evergreen.V367.Coord
import Evergreen.V367.CssPixels
import Evergreen.V367.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V367.FileStatus.FileHash (Maybe (Evergreen.V367.Coord.Coord Evergreen.V367.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
