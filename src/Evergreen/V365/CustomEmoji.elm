module Evergreen.V365.CustomEmoji exposing (..)

import Evergreen.V365.Coord
import Evergreen.V365.CssPixels
import Evergreen.V365.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V365.FileStatus.FileHash (Maybe (Evergreen.V365.Coord.Coord Evergreen.V365.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
