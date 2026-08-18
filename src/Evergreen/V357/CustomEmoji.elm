module Evergreen.V357.CustomEmoji exposing (..)

import Evergreen.V357.Coord
import Evergreen.V357.CssPixels
import Evergreen.V357.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V357.FileStatus.FileHash (Maybe (Evergreen.V357.Coord.Coord Evergreen.V357.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
