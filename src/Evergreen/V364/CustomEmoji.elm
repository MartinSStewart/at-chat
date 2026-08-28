module Evergreen.V364.CustomEmoji exposing (..)

import Evergreen.V364.Coord
import Evergreen.V364.CssPixels
import Evergreen.V364.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V364.FileStatus.FileHash (Maybe (Evergreen.V364.Coord.Coord Evergreen.V364.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
