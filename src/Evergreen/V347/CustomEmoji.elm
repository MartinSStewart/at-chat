module Evergreen.V347.CustomEmoji exposing (..)

import Evergreen.V347.Coord
import Evergreen.V347.CssPixels
import Evergreen.V347.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V347.FileStatus.FileHash (Maybe (Evergreen.V347.Coord.Coord Evergreen.V347.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
