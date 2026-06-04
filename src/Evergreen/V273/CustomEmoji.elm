module Evergreen.V273.CustomEmoji exposing (..)

import Evergreen.V273.Coord
import Evergreen.V273.CssPixels
import Evergreen.V273.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V273.FileStatus.FileHash (Maybe (Evergreen.V273.Coord.Coord Evergreen.V273.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
