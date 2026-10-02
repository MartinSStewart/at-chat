module Evergreen.V396.CustomEmoji exposing (..)

import Evergreen.V396.Coord
import Evergreen.V396.CssPixels
import Evergreen.V396.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V396.FileStatus.FileHash (Maybe (Evergreen.V396.Coord.Coord Evergreen.V396.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
