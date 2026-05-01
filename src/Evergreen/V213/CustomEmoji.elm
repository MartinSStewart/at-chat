module Evergreen.V213.CustomEmoji exposing (..)

import Evergreen.V213.Coord
import Evergreen.V213.CssPixels
import Evergreen.V213.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V213.FileStatus.FileHash (Maybe (Evergreen.V213.Coord.Coord Evergreen.V213.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
