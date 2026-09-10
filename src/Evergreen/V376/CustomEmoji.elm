module Evergreen.V376.CustomEmoji exposing (..)

import Evergreen.V376.Coord
import Evergreen.V376.CssPixels
import Evergreen.V376.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V376.FileStatus.FileHash (Maybe (Evergreen.V376.Coord.Coord Evergreen.V376.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
