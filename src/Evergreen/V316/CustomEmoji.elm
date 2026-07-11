module Evergreen.V316.CustomEmoji exposing (..)

import Evergreen.V316.Coord
import Evergreen.V316.CssPixels
import Evergreen.V316.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V316.FileStatus.FileHash (Maybe (Evergreen.V316.Coord.Coord Evergreen.V316.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
