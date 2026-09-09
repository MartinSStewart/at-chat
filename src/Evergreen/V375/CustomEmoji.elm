module Evergreen.V375.CustomEmoji exposing (..)

import Evergreen.V375.Coord
import Evergreen.V375.CssPixels
import Evergreen.V375.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V375.FileStatus.FileHash (Maybe (Evergreen.V375.Coord.Coord Evergreen.V375.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
