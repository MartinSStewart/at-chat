module Evergreen.V345.CustomEmoji exposing (..)

import Evergreen.V345.Coord
import Evergreen.V345.CssPixels
import Evergreen.V345.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V345.FileStatus.FileHash (Maybe (Evergreen.V345.Coord.Coord Evergreen.V345.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
