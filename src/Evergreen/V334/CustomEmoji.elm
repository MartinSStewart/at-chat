module Evergreen.V334.CustomEmoji exposing (..)

import Evergreen.V334.Coord
import Evergreen.V334.CssPixels
import Evergreen.V334.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V334.FileStatus.FileHash (Maybe (Evergreen.V334.Coord.Coord Evergreen.V334.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
