module Evergreen.V406.CustomEmoji exposing (..)

import Evergreen.V406.Coord
import Evergreen.V406.CssPixels
import Evergreen.V406.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V406.FileStatus.FileHash (Maybe (Evergreen.V406.Coord.Coord Evergreen.V406.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
