module Evergreen.V327.CustomEmoji exposing (..)

import Evergreen.V327.Coord
import Evergreen.V327.CssPixels
import Evergreen.V327.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V327.FileStatus.FileHash (Maybe (Evergreen.V327.Coord.Coord Evergreen.V327.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
