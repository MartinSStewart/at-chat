module Evergreen.V251.CustomEmoji exposing (..)

import Evergreen.V251.Coord
import Evergreen.V251.CssPixels
import Evergreen.V251.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V251.FileStatus.FileHash (Maybe (Evergreen.V251.Coord.Coord Evergreen.V251.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
