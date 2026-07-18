module Evergreen.V328.CustomEmoji exposing (..)

import Evergreen.V328.Coord
import Evergreen.V328.CssPixels
import Evergreen.V328.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V328.FileStatus.FileHash (Maybe (Evergreen.V328.Coord.Coord Evergreen.V328.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
