module Evergreen.V228.CustomEmoji exposing (..)

import Evergreen.V228.Coord
import Evergreen.V228.CssPixels
import Evergreen.V228.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V228.FileStatus.FileHash (Maybe (Evergreen.V228.Coord.Coord Evergreen.V228.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
