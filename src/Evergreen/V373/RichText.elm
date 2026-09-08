module Evergreen.V373.RichText exposing (..)

import Evergreen.V373.Coord
import Evergreen.V373.CssPixels
import Evergreen.V373.CustomEmoji
import Evergreen.V373.Discord
import Evergreen.V373.FileStatus
import Evergreen.V373.Id
import Evergreen.V373.Point2d
import Evergreen.V373.TimeInMinutes
import Evergreen.V373.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V373.Point2d.Point2d Evergreen.V373.CssPixels.CssPixels Evergreen.V373.Touch.ScreenCoordinate
    , imageSize : Evergreen.V373.Coord.Coord Evergreen.V373.CssPixels.CssPixels
    , displayWidth : Float
    }


type HasLeadingLineBreak
    = HasLeadingLineBreak
    | NoLeadingLineBreak


type HeadingLevel
    = H1
    | H2
    | H3
    | Small


type Language
    = Language String.Nonempty.NonemptyString
    | NoLanguage


type EscapedChar
    = EscapedSquareBracket
    | EscapedBackslash
    | EscapedBacktick
    | EscapedAtSymbol
    | EscapedBold
    | EscapedItalic
    | EscapedStrikethrough
    | EscapedSpoilered


type RichText userId
    = UserMention userId
    | NormalText Char String
    | Bold (List.Nonempty.Nonempty (RichText userId))
    | Italic (List.Nonempty.Nonempty (RichText userId))
    | Underline (List.Nonempty.Nonempty (RichText userId))
    | Strikethrough (List.Nonempty.Nonempty (RichText userId))
    | Spoiler (List.Nonempty.Nonempty (RichText userId))
    | BlockQuote HasLeadingLineBreak (List (RichText userId))
    | Heading HeadingLevel HasLeadingLineBreak (List.Nonempty.Nonempty (RichText userId))
    | Hyperlink Url.Url
    | MarkdownLink String.Nonempty.NonemptyString Url.Url
    | InlineCode Char String
    | CodeBlock Language String
    | AttachedFile (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V373.Id.Id Evergreen.V373.Id.StickerId)
    | CustomEmoji (Evergreen.V373.Id.Id Evergreen.V373.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V373.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V373.Discord.Id Evergreen.V373.Discord.CustomEmojiId
    , name : Evergreen.V373.CustomEmoji.EmojiName
    }
