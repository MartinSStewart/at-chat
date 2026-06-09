module Evergreen.V283.CustomEmoji exposing (..)

import Evergreen.V283.Coord
import Evergreen.V283.CssPixels
import Evergreen.V283.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V283.FileStatus.FileHash (Maybe (Evergreen.V283.Coord.Coord Evergreen.V283.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
