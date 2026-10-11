module Evergreen.V403.CustomEmoji exposing (..)

import Evergreen.V403.Coord
import Evergreen.V403.CssPixels
import Evergreen.V403.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V403.FileStatus.FileHash (Maybe (Evergreen.V403.Coord.Coord Evergreen.V403.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
