module Evergreen.V377.CustomEmoji exposing (..)

import Evergreen.V377.Coord
import Evergreen.V377.CssPixels
import Evergreen.V377.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V377.FileStatus.FileHash (Maybe (Evergreen.V377.Coord.Coord Evergreen.V377.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
