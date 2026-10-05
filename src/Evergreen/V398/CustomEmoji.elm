module Evergreen.V398.CustomEmoji exposing (..)

import Evergreen.V398.Coord
import Evergreen.V398.CssPixels
import Evergreen.V398.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V398.FileStatus.FileHash (Maybe (Evergreen.V398.Coord.Coord Evergreen.V398.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
