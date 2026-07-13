module Evergreen.V317.CustomEmoji exposing (..)

import Evergreen.V317.Coord
import Evergreen.V317.CssPixels
import Evergreen.V317.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V317.FileStatus.FileHash (Maybe (Evergreen.V317.Coord.Coord Evergreen.V317.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
