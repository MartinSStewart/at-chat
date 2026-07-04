module Evergreen.V302.CustomEmoji exposing (..)

import Evergreen.V302.Coord
import Evergreen.V302.CssPixels
import Evergreen.V302.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V302.FileStatus.FileHash (Maybe (Evergreen.V302.Coord.Coord Evergreen.V302.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
