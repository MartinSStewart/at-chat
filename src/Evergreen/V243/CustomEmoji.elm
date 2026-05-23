module Evergreen.V243.CustomEmoji exposing (..)

import Evergreen.V243.Coord
import Evergreen.V243.CssPixels
import Evergreen.V243.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V243.FileStatus.FileHash (Maybe (Evergreen.V243.Coord.Coord Evergreen.V243.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
