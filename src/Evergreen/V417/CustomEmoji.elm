module Evergreen.V417.CustomEmoji exposing (..)

import Evergreen.V417.Coord
import Evergreen.V417.CssPixels
import Evergreen.V417.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V417.FileStatus.FileHash (Maybe (Evergreen.V417.Coord.Coord Evergreen.V417.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
