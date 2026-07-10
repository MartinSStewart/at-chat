module Evergreen.V311.CustomEmoji exposing (..)

import Evergreen.V311.Coord
import Evergreen.V311.CssPixels
import Evergreen.V311.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V311.FileStatus.FileHash (Maybe (Evergreen.V311.Coord.Coord Evergreen.V311.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
