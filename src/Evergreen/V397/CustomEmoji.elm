module Evergreen.V397.CustomEmoji exposing (..)

import Evergreen.V397.Coord
import Evergreen.V397.CssPixels
import Evergreen.V397.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V397.FileStatus.FileHash (Maybe (Evergreen.V397.Coord.Coord Evergreen.V397.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
