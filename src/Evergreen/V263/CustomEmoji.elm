module Evergreen.V263.CustomEmoji exposing (..)

import Evergreen.V263.Coord
import Evergreen.V263.CssPixels
import Evergreen.V263.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V263.FileStatus.FileHash (Maybe (Evergreen.V263.Coord.Coord Evergreen.V263.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
