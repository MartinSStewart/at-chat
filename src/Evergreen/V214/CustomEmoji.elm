module Evergreen.V214.CustomEmoji exposing (..)

import Evergreen.V214.Coord
import Evergreen.V214.CssPixels
import Evergreen.V214.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V214.FileStatus.FileHash (Maybe (Evergreen.V214.Coord.Coord Evergreen.V214.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
