module Evergreen.V262.CustomEmoji exposing (..)

import Evergreen.V262.Coord
import Evergreen.V262.CssPixels
import Evergreen.V262.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V262.FileStatus.FileHash (Maybe (Evergreen.V262.Coord.Coord Evergreen.V262.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
