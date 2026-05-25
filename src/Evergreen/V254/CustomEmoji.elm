module Evergreen.V254.CustomEmoji exposing (..)

import Evergreen.V254.Coord
import Evergreen.V254.CssPixels
import Evergreen.V254.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V254.FileStatus.FileHash (Maybe (Evergreen.V254.Coord.Coord Evergreen.V254.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
