module Evergreen.V333.CustomEmoji exposing (..)

import Evergreen.V333.Coord
import Evergreen.V333.CssPixels
import Evergreen.V333.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V333.FileStatus.FileHash (Maybe (Evergreen.V333.Coord.Coord Evergreen.V333.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
