module Evergreen.V296.CustomEmoji exposing (..)

import Evergreen.V296.Coord
import Evergreen.V296.CssPixels
import Evergreen.V296.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V296.FileStatus.FileHash (Maybe (Evergreen.V296.Coord.Coord Evergreen.V296.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
