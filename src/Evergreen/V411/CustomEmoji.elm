module Evergreen.V411.CustomEmoji exposing (..)

import Evergreen.V411.Coord
import Evergreen.V411.CssPixels
import Evergreen.V411.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V411.FileStatus.FileHash (Maybe (Evergreen.V411.Coord.Coord Evergreen.V411.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
