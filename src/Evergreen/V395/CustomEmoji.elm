module Evergreen.V395.CustomEmoji exposing (..)

import Evergreen.V395.Coord
import Evergreen.V395.CssPixels
import Evergreen.V395.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V395.FileStatus.FileHash (Maybe (Evergreen.V395.Coord.Coord Evergreen.V395.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
