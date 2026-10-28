module Evergreen.V419.CustomEmoji exposing (..)

import Evergreen.V419.Coord
import Evergreen.V419.CssPixels
import Evergreen.V419.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V419.FileStatus.FileHash (Maybe (Evergreen.V419.Coord.Coord Evergreen.V419.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
