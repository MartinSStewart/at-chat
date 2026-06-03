module Evergreen.V270.CustomEmoji exposing (..)

import Evergreen.V270.Coord
import Evergreen.V270.CssPixels
import Evergreen.V270.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V270.FileStatus.FileHash (Maybe (Evergreen.V270.Coord.Coord Evergreen.V270.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
