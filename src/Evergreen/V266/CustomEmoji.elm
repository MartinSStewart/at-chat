module Evergreen.V266.CustomEmoji exposing (..)

import Evergreen.V266.Coord
import Evergreen.V266.CssPixels
import Evergreen.V266.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V266.FileStatus.FileHash (Maybe (Evergreen.V266.Coord.Coord Evergreen.V266.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
