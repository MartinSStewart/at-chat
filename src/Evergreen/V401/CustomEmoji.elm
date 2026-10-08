module Evergreen.V401.CustomEmoji exposing (..)

import Evergreen.V401.Coord
import Evergreen.V401.CssPixels
import Evergreen.V401.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V401.FileStatus.FileHash (Maybe (Evergreen.V401.Coord.Coord Evergreen.V401.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
