module Evergreen.V236.CustomEmoji exposing (..)

import Evergreen.V236.Coord
import Evergreen.V236.CssPixels
import Evergreen.V236.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V236.FileStatus.FileHash (Maybe (Evergreen.V236.Coord.Coord Evergreen.V236.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
