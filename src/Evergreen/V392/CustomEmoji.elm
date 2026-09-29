module Evergreen.V392.CustomEmoji exposing (..)

import Evergreen.V392.Coord
import Evergreen.V392.CssPixels
import Evergreen.V392.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V392.FileStatus.FileHash (Maybe (Evergreen.V392.Coord.Coord Evergreen.V392.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
