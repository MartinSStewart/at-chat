module Evergreen.V344.CustomEmoji exposing (..)

import Evergreen.V344.Coord
import Evergreen.V344.CssPixels
import Evergreen.V344.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V344.FileStatus.FileHash (Maybe (Evergreen.V344.Coord.Coord Evergreen.V344.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
