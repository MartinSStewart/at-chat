module Evergreen.V422.CustomEmoji exposing (..)

import Evergreen.V422.Coord
import Evergreen.V422.CssPixels
import Evergreen.V422.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V422.FileStatus.FileHash (Maybe (Evergreen.V422.Coord.Coord Evergreen.V422.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
