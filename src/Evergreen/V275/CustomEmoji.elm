module Evergreen.V275.CustomEmoji exposing (..)

import Evergreen.V275.Coord
import Evergreen.V275.CssPixels
import Evergreen.V275.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V275.FileStatus.FileHash (Maybe (Evergreen.V275.Coord.Coord Evergreen.V275.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
