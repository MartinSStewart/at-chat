module Evergreen.V385.CustomEmoji exposing (..)

import Evergreen.V385.Coord
import Evergreen.V385.CssPixels
import Evergreen.V385.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V385.FileStatus.FileHash (Maybe (Evergreen.V385.Coord.Coord Evergreen.V385.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
