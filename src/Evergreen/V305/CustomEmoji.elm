module Evergreen.V305.CustomEmoji exposing (..)

import Evergreen.V305.Coord
import Evergreen.V305.CssPixels
import Evergreen.V305.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V305.FileStatus.FileHash (Maybe (Evergreen.V305.Coord.Coord Evergreen.V305.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
