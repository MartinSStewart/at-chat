module Evergreen.V378.CustomEmoji exposing (..)

import Evergreen.V378.Coord
import Evergreen.V378.CssPixels
import Evergreen.V378.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V378.FileStatus.FileHash (Maybe (Evergreen.V378.Coord.Coord Evergreen.V378.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
