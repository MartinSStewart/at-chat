module Evergreen.V223.CustomEmoji exposing (..)

import Evergreen.V223.Coord
import Evergreen.V223.CssPixels
import Evergreen.V223.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V223.FileStatus.FileHash (Maybe (Evergreen.V223.Coord.Coord Evergreen.V223.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
