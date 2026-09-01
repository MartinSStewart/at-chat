module Evergreen.V366.CustomEmoji exposing (..)

import Evergreen.V366.Coord
import Evergreen.V366.CssPixels
import Evergreen.V366.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V366.FileStatus.FileHash (Maybe (Evergreen.V366.Coord.Coord Evergreen.V366.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
