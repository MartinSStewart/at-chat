module Evergreen.V382.CustomEmoji exposing (..)

import Evergreen.V382.Coord
import Evergreen.V382.CssPixels
import Evergreen.V382.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V382.FileStatus.FileHash (Maybe (Evergreen.V382.Coord.Coord Evergreen.V382.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
