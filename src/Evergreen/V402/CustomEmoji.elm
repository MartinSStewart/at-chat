module Evergreen.V402.CustomEmoji exposing (..)

import Evergreen.V402.Coord
import Evergreen.V402.CssPixels
import Evergreen.V402.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V402.FileStatus.FileHash (Maybe (Evergreen.V402.Coord.Coord Evergreen.V402.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
