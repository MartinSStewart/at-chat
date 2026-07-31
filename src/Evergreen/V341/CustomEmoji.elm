module Evergreen.V341.CustomEmoji exposing (..)

import Evergreen.V341.Coord
import Evergreen.V341.CssPixels
import Evergreen.V341.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V341.FileStatus.FileHash (Maybe (Evergreen.V341.Coord.Coord Evergreen.V341.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
