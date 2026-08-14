module Evergreen.V352.CustomEmoji exposing (..)

import Evergreen.V352.Coord
import Evergreen.V352.CssPixels
import Evergreen.V352.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V352.FileStatus.FileHash (Maybe (Evergreen.V352.Coord.Coord Evergreen.V352.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
