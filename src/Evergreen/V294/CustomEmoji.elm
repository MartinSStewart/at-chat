module Evergreen.V294.CustomEmoji exposing (..)

import Evergreen.V294.Coord
import Evergreen.V294.CssPixels
import Evergreen.V294.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V294.FileStatus.FileHash (Maybe (Evergreen.V294.Coord.Coord Evergreen.V294.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
