module Evergreen.V250.CustomEmoji exposing (..)

import Evergreen.V250.Coord
import Evergreen.V250.CssPixels
import Evergreen.V250.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V250.FileStatus.FileHash (Maybe (Evergreen.V250.Coord.Coord Evergreen.V250.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
