module Evergreen.V279.CustomEmoji exposing (..)

import Evergreen.V279.Coord
import Evergreen.V279.CssPixels
import Evergreen.V279.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V279.FileStatus.FileHash (Maybe (Evergreen.V279.Coord.Coord Evergreen.V279.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
