module Evergreen.V383.CustomEmoji exposing (..)

import Evergreen.V383.Coord
import Evergreen.V383.CssPixels
import Evergreen.V383.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V383.FileStatus.FileHash (Maybe (Evergreen.V383.Coord.Coord Evergreen.V383.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
