module Evergreen.V309.CustomEmoji exposing (..)

import Evergreen.V309.Coord
import Evergreen.V309.CssPixels
import Evergreen.V309.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V309.FileStatus.FileHash (Maybe (Evergreen.V309.Coord.Coord Evergreen.V309.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
