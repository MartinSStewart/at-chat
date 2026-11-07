module Evergreen.V421.CustomEmoji exposing (..)

import Evergreen.V421.Coord
import Evergreen.V421.CssPixels
import Evergreen.V421.FileStatus


type CustomEmojiUrl
    = CustomEmojiInternal Evergreen.V421.FileStatus.FileHash (Maybe (Evergreen.V421.Coord.Coord Evergreen.V421.CssPixels.CssPixels))
    | CustomEmojiLoading


type EmojiName
    = EmojiName String


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }
