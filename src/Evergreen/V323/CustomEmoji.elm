module Evergreen.V323.CustomEmoji exposing (..)

import Evergreen.V323.Coord
import Evergreen.V323.CssPixels
import Evergreen.V323.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V323.FileStatus.FileHash (Maybe (Evergreen.V323.Coord.Coord Evergreen.V323.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
