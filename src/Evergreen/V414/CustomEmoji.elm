module Evergreen.V414.CustomEmoji exposing (..)

import Evergreen.V414.Coord
import Evergreen.V414.CssPixels
import Evergreen.V414.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V414.FileStatus.FileHash (Maybe (Evergreen.V414.Coord.Coord Evergreen.V414.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
