module Evergreen.V269.CustomEmoji exposing (..)

import Evergreen.V269.Coord
import Evergreen.V269.CssPixels
import Evergreen.V269.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V269.FileStatus.FileHash (Maybe (Evergreen.V269.Coord.Coord Evergreen.V269.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
