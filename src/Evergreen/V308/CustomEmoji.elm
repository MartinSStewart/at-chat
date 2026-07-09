module Evergreen.V308.CustomEmoji exposing (..)

import Evergreen.V308.Coord
import Evergreen.V308.CssPixels
import Evergreen.V308.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V308.FileStatus.FileHash (Maybe (Evergreen.V308.Coord.Coord Evergreen.V308.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
