module Evergreen.V293.CustomEmoji exposing (..)

import Evergreen.V293.Coord
import Evergreen.V293.CssPixels
import Evergreen.V293.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V293.FileStatus.FileHash (Maybe (Evergreen.V293.Coord.Coord Evergreen.V293.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
