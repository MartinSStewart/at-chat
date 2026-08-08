module Evergreen.V348.CustomEmoji exposing (..)

import Evergreen.V348.Coord
import Evergreen.V348.CssPixels
import Evergreen.V348.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V348.FileStatus.FileHash (Maybe (Evergreen.V348.Coord.Coord Evergreen.V348.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
