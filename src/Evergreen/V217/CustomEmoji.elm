module Evergreen.V217.CustomEmoji exposing (..)

import Evergreen.V217.Coord
import Evergreen.V217.CssPixels
import Evergreen.V217.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V217.FileStatus.FileHash (Maybe (Evergreen.V217.Coord.Coord Evergreen.V217.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
