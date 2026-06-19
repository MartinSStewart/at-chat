module Evergreen.V290.CustomEmoji exposing (..)

import Evergreen.V290.Coord
import Evergreen.V290.CssPixels
import Evergreen.V290.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V290.FileStatus.FileHash (Maybe (Evergreen.V290.Coord.Coord Evergreen.V290.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
