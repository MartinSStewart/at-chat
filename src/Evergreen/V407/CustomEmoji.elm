module Evergreen.V407.CustomEmoji exposing (..)

import Evergreen.V407.Coord
import Evergreen.V407.CssPixels
import Evergreen.V407.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V407.FileStatus.FileHash (Maybe (Evergreen.V407.Coord.Coord Evergreen.V407.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
