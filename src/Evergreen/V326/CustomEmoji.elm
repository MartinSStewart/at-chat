module Evergreen.V326.CustomEmoji exposing (..)

import Evergreen.V326.Coord
import Evergreen.V326.CssPixels
import Evergreen.V326.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V326.FileStatus.FileHash (Maybe (Evergreen.V326.Coord.Coord Evergreen.V326.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
