module Evergreen.V253.CustomEmoji exposing (..)

import Evergreen.V253.Coord
import Evergreen.V253.CssPixels
import Evergreen.V253.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V253.FileStatus.FileHash (Maybe (Evergreen.V253.Coord.Coord Evergreen.V253.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
