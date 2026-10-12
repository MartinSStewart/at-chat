module Evergreen.V405.CustomEmoji exposing (..)

import Evergreen.V405.Coord
import Evergreen.V405.CssPixels
import Evergreen.V405.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V405.FileStatus.FileHash (Maybe (Evergreen.V405.Coord.Coord Evergreen.V405.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
