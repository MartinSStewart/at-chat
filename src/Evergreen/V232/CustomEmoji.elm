module Evergreen.V232.CustomEmoji exposing (..)

import Evergreen.V232.Coord
import Evergreen.V232.CssPixels
import Evergreen.V232.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V232.FileStatus.FileHash (Maybe (Evergreen.V232.Coord.Coord Evergreen.V232.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
