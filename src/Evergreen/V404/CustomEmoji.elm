module Evergreen.V404.CustomEmoji exposing (..)

import Evergreen.V404.Coord
import Evergreen.V404.CssPixels
import Evergreen.V404.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V404.FileStatus.FileHash (Maybe (Evergreen.V404.Coord.Coord Evergreen.V404.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
