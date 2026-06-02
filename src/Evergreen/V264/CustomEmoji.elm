module Evergreen.V264.CustomEmoji exposing (..)

import Evergreen.V264.Coord
import Evergreen.V264.CssPixels
import Evergreen.V264.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V264.FileStatus.FileHash (Maybe (Evergreen.V264.Coord.Coord Evergreen.V264.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
