module Evergreen.V240.CustomEmoji exposing (..)

import Evergreen.V240.Coord
import Evergreen.V240.CssPixels
import Evergreen.V240.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V240.FileStatus.FileHash (Maybe (Evergreen.V240.Coord.Coord Evergreen.V240.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
