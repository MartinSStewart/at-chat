module Evergreen.V426.CustomEmoji exposing (..)

import Evergreen.V426.Coord
import Evergreen.V426.CssPixels
import Evergreen.V426.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V426.FileStatus.FileHash (Maybe (Evergreen.V426.Coord.Coord Evergreen.V426.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
