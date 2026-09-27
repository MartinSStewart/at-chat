module Evergreen.V386.CustomEmoji exposing (..)

import Evergreen.V386.Coord
import Evergreen.V386.CssPixels
import Evergreen.V386.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V386.FileStatus.FileHash (Maybe (Evergreen.V386.Coord.Coord Evergreen.V386.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
