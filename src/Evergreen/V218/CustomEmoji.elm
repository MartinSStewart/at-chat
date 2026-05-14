module Evergreen.V218.CustomEmoji exposing (..)

import Evergreen.V218.Coord
import Evergreen.V218.CssPixels
import Evergreen.V218.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V218.FileStatus.FileHash (Maybe (Evergreen.V218.Coord.Coord Evergreen.V218.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
