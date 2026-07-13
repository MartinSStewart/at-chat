module Evergreen.V318.CustomEmoji exposing (..)

import Evergreen.V318.Coord
import Evergreen.V318.CssPixels
import Evergreen.V318.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V318.FileStatus.FileHash (Maybe (Evergreen.V318.Coord.Coord Evergreen.V318.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
