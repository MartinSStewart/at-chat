module Evergreen.V216.CustomEmoji exposing (..)

import Evergreen.V216.Coord
import Evergreen.V216.CssPixels
import Evergreen.V216.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V216.FileStatus.FileHash (Maybe (Evergreen.V216.Coord.Coord Evergreen.V216.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
