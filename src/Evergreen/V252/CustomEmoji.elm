module Evergreen.V252.CustomEmoji exposing (..)

import Evergreen.V252.Coord
import Evergreen.V252.CssPixels
import Evergreen.V252.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V252.FileStatus.FileHash (Maybe (Evergreen.V252.Coord.Coord Evergreen.V252.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
