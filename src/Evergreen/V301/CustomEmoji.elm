module Evergreen.V301.CustomEmoji exposing (..)

import Evergreen.V301.Coord
import Evergreen.V301.CssPixels
import Evergreen.V301.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V301.FileStatus.FileHash (Maybe (Evergreen.V301.Coord.Coord Evergreen.V301.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
