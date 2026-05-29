module Evergreen.V261.CustomEmoji exposing (..)

import Evergreen.V261.Coord
import Evergreen.V261.CssPixels
import Evergreen.V261.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V261.FileStatus.FileHash (Maybe (Evergreen.V261.Coord.Coord Evergreen.V261.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
