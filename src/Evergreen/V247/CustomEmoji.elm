module Evergreen.V247.CustomEmoji exposing (..)

import Evergreen.V247.Coord
import Evergreen.V247.CssPixels
import Evergreen.V247.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V247.FileStatus.FileHash (Maybe (Evergreen.V247.Coord.Coord Evergreen.V247.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
