module Evergreen.V387.CustomEmoji exposing (..)

import Evergreen.V387.Coord
import Evergreen.V387.CssPixels
import Evergreen.V387.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V387.FileStatus.FileHash (Maybe (Evergreen.V387.Coord.Coord Evergreen.V387.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
