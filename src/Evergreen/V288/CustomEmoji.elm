module Evergreen.V288.CustomEmoji exposing (..)

import Evergreen.V288.Coord
import Evergreen.V288.CssPixels
import Evergreen.V288.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V288.FileStatus.FileHash (Maybe (Evergreen.V288.Coord.Coord Evergreen.V288.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
