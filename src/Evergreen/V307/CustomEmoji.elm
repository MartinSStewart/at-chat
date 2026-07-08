module Evergreen.V307.CustomEmoji exposing (..)

import Evergreen.V307.Coord
import Evergreen.V307.CssPixels
import Evergreen.V307.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V307.FileStatus.FileHash (Maybe (Evergreen.V307.Coord.Coord Evergreen.V307.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
