module Evergreen.V285.CustomEmoji exposing (..)

import Evergreen.V285.Coord
import Evergreen.V285.CssPixels
import Evergreen.V285.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V285.FileStatus.FileHash (Maybe (Evergreen.V285.Coord.Coord Evergreen.V285.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
