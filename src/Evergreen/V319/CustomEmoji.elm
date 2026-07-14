module Evergreen.V319.CustomEmoji exposing (..)

import Evergreen.V319.Coord
import Evergreen.V319.CssPixels
import Evergreen.V319.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V319.FileStatus.FileHash (Maybe (Evergreen.V319.Coord.Coord Evergreen.V319.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
