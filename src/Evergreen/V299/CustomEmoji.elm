module Evergreen.V299.CustomEmoji exposing (..)

import Evergreen.V299.Coord
import Evergreen.V299.CssPixels
import Evergreen.V299.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V299.FileStatus.FileHash (Maybe (Evergreen.V299.Coord.Coord Evergreen.V299.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
