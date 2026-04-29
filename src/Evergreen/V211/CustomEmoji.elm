module Evergreen.V211.CustomEmoji exposing (..)

import Evergreen.V211.Coord
import Evergreen.V211.CssPixels
import Evergreen.V211.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V211.FileStatus.FileHash (Maybe (Evergreen.V211.Coord.Coord Evergreen.V211.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
