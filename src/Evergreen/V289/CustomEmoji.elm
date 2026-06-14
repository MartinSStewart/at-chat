module Evergreen.V289.CustomEmoji exposing (..)

import Evergreen.V289.Coord
import Evergreen.V289.CssPixels
import Evergreen.V289.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V289.FileStatus.FileHash (Maybe (Evergreen.V289.Coord.Coord Evergreen.V289.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
