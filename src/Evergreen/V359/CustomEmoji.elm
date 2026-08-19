module Evergreen.V359.CustomEmoji exposing (..)

import Evergreen.V359.Coord
import Evergreen.V359.CssPixels
import Evergreen.V359.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V359.FileStatus.FileHash (Maybe (Evergreen.V359.Coord.Coord Evergreen.V359.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
