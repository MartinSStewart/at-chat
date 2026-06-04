module Evergreen.V271.CustomEmoji exposing (..)

import Evergreen.V271.Coord
import Evergreen.V271.CssPixels
import Evergreen.V271.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V271.FileStatus.FileHash (Maybe (Evergreen.V271.Coord.Coord Evergreen.V271.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
