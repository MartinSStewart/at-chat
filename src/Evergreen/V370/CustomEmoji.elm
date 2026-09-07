module Evergreen.V370.CustomEmoji exposing (..)

import Evergreen.V370.Coord
import Evergreen.V370.CssPixels
import Evergreen.V370.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V370.FileStatus.FileHash (Maybe (Evergreen.V370.Coord.Coord Evergreen.V370.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
