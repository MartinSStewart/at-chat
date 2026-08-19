module Evergreen.V358.CustomEmoji exposing (..)

import Evergreen.V358.Coord
import Evergreen.V358.CssPixels
import Evergreen.V358.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V358.FileStatus.FileHash (Maybe (Evergreen.V358.Coord.Coord Evergreen.V358.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
