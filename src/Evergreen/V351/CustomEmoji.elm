module Evergreen.V351.CustomEmoji exposing (..)

import Evergreen.V351.Coord
import Evergreen.V351.CssPixels
import Evergreen.V351.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V351.FileStatus.FileHash (Maybe (Evergreen.V351.Coord.Coord Evergreen.V351.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
