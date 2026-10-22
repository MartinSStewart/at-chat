module Evergreen.V408.CustomEmoji exposing (..)

import Evergreen.V408.Coord
import Evergreen.V408.CssPixels
import Evergreen.V408.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V408.FileStatus.FileHash (Maybe (Evergreen.V408.Coord.Coord Evergreen.V408.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
