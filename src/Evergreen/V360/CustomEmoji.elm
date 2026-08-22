module Evergreen.V360.CustomEmoji exposing (..)

import Evergreen.V360.Coord
import Evergreen.V360.CssPixels
import Evergreen.V360.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V360.FileStatus.FileHash (Maybe (Evergreen.V360.Coord.Coord Evergreen.V360.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
