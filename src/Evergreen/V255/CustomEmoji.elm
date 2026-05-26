module Evergreen.V255.CustomEmoji exposing (..)

import Evergreen.V255.Coord
import Evergreen.V255.CssPixels
import Evergreen.V255.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V255.FileStatus.FileHash (Maybe (Evergreen.V255.Coord.Coord Evergreen.V255.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
