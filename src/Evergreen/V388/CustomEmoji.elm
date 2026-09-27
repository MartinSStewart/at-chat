module Evergreen.V388.CustomEmoji exposing (..)

import Evergreen.V388.Coord
import Evergreen.V388.CssPixels
import Evergreen.V388.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V388.FileStatus.FileHash (Maybe (Evergreen.V388.Coord.Coord Evergreen.V388.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
