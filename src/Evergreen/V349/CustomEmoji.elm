module Evergreen.V349.CustomEmoji exposing (..)

import Evergreen.V349.Coord
import Evergreen.V349.CssPixels
import Evergreen.V349.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V349.FileStatus.FileHash (Maybe (Evergreen.V349.Coord.Coord Evergreen.V349.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
