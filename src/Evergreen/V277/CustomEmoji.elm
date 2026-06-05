module Evergreen.V277.CustomEmoji exposing (..)

import Evergreen.V277.Coord
import Evergreen.V277.CssPixels
import Evergreen.V277.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V277.FileStatus.FileHash (Maybe (Evergreen.V277.Coord.Coord Evergreen.V277.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
