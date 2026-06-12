module Evergreen.V286.CustomEmoji exposing (..)

import Evergreen.V286.Coord
import Evergreen.V286.CssPixels
import Evergreen.V286.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V286.FileStatus.FileHash (Maybe (Evergreen.V286.Coord.Coord Evergreen.V286.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
