module Evergreen.V257.CustomEmoji exposing (..)

import Evergreen.V257.Coord
import Evergreen.V257.CssPixels
import Evergreen.V257.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V257.FileStatus.FileHash (Maybe (Evergreen.V257.Coord.Coord Evergreen.V257.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
