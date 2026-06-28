module Evergreen.V295.CustomEmoji exposing (..)

import Evergreen.V295.Coord
import Evergreen.V295.CssPixels
import Evergreen.V295.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V295.FileStatus.FileHash (Maybe (Evergreen.V295.Coord.Coord Evergreen.V295.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
