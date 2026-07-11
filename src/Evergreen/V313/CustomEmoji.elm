module Evergreen.V313.CustomEmoji exposing (..)

import Evergreen.V313.Coord
import Evergreen.V313.CssPixels
import Evergreen.V313.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V313.FileStatus.FileHash (Maybe (Evergreen.V313.Coord.Coord Evergreen.V313.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
