module Evergreen.V346.CustomEmoji exposing (..)

import Evergreen.V346.Coord
import Evergreen.V346.CssPixels
import Evergreen.V346.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V346.FileStatus.FileHash (Maybe (Evergreen.V346.Coord.Coord Evergreen.V346.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
