module Evergreen.V343.CustomEmoji exposing (..)

import Evergreen.V343.Coord
import Evergreen.V343.CssPixels
import Evergreen.V343.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V343.FileStatus.FileHash (Maybe (Evergreen.V343.Coord.Coord Evergreen.V343.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
