module Evergreen.V239.CustomEmoji exposing (..)

import Evergreen.V239.Coord
import Evergreen.V239.CssPixels
import Evergreen.V239.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V239.FileStatus.FileHash (Maybe (Evergreen.V239.Coord.Coord Evergreen.V239.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
