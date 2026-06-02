module Evergreen.V267.CustomEmoji exposing (..)

import Evergreen.V267.Coord
import Evergreen.V267.CssPixels
import Evergreen.V267.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V267.FileStatus.FileHash (Maybe (Evergreen.V267.Coord.Coord Evergreen.V267.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
