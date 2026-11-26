module Evergreen.V425.CustomEmoji exposing (..)

import Evergreen.V425.Coord
import Evergreen.V425.CssPixels
import Evergreen.V425.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V425.FileStatus.FileHash (Maybe (Evergreen.V425.Coord.Coord Evergreen.V425.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
