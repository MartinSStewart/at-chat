module Evergreen.V287.CustomEmoji exposing (..)

import Evergreen.V287.Coord
import Evergreen.V287.CssPixels
import Evergreen.V287.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V287.FileStatus.FileHash (Maybe (Evergreen.V287.Coord.Coord Evergreen.V287.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
