module Evergreen.V298.CustomEmoji exposing (..)

import Evergreen.V298.Coord
import Evergreen.V298.CssPixels
import Evergreen.V298.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V298.FileStatus.FileHash (Maybe (Evergreen.V298.Coord.Coord Evergreen.V298.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
