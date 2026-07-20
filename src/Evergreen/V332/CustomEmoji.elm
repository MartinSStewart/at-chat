module Evergreen.V332.CustomEmoji exposing (..)

import Evergreen.V332.Coord
import Evergreen.V332.CssPixels
import Evergreen.V332.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V332.FileStatus.FileHash (Maybe (Evergreen.V332.Coord.Coord Evergreen.V332.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
