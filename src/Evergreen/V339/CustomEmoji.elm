module Evergreen.V339.CustomEmoji exposing (..)

import Evergreen.V339.Coord
import Evergreen.V339.CssPixels
import Evergreen.V339.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V339.FileStatus.FileHash (Maybe (Evergreen.V339.Coord.Coord Evergreen.V339.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
