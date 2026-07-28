module Evergreen.V338.CustomEmoji exposing (..)

import Evergreen.V338.Coord
import Evergreen.V338.CssPixels
import Evergreen.V338.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V338.FileStatus.FileHash (Maybe (Evergreen.V338.Coord.Coord Evergreen.V338.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
