module Evergreen.V372.CustomEmoji exposing (..)

import Evergreen.V372.Coord
import Evergreen.V372.CssPixels
import Evergreen.V372.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V372.FileStatus.FileHash (Maybe (Evergreen.V372.Coord.Coord Evergreen.V372.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
