module Evergreen.V315.CustomEmoji exposing (..)

import Evergreen.V315.Coord
import Evergreen.V315.CssPixels
import Evergreen.V315.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V315.FileStatus.FileHash (Maybe (Evergreen.V315.Coord.Coord Evergreen.V315.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
