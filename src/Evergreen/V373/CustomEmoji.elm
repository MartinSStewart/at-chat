module Evergreen.V373.CustomEmoji exposing (..)

import Evergreen.V373.Coord
import Evergreen.V373.CssPixels
import Evergreen.V373.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V373.FileStatus.FileHash (Maybe (Evergreen.V373.Coord.Coord Evergreen.V373.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
