module Evergreen.V412.CustomEmoji exposing (..)

import Evergreen.V412.Coord
import Evergreen.V412.CssPixels
import Evergreen.V412.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V412.FileStatus.FileHash (Maybe (Evergreen.V412.Coord.Coord Evergreen.V412.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
