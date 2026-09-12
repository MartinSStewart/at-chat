module Evergreen.V379.CustomEmoji exposing (..)

import Evergreen.V379.Coord
import Evergreen.V379.CssPixels
import Evergreen.V379.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V379.FileStatus.FileHash (Maybe (Evergreen.V379.Coord.Coord Evergreen.V379.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
