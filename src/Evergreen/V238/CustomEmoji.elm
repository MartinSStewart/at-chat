module Evergreen.V238.CustomEmoji exposing (..)

import Evergreen.V238.Coord
import Evergreen.V238.CssPixels
import Evergreen.V238.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V238.FileStatus.FileHash (Maybe (Evergreen.V238.Coord.Coord Evergreen.V238.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
