module Evergreen.V242.CustomEmoji exposing (..)

import Evergreen.V242.Coord
import Evergreen.V242.CssPixels
import Evergreen.V242.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V242.FileStatus.FileHash (Maybe (Evergreen.V242.Coord.Coord Evergreen.V242.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
