module Evergreen.V348.RichText exposing (..)

import Evergreen.V348.Coord
import Evergreen.V348.CssPixels
import Evergreen.V348.CustomEmoji
import Evergreen.V348.Discord
import Evergreen.V348.FileStatus
import Evergreen.V348.Id
import Evergreen.V348.Point2d
import Evergreen.V348.TimeInMinutes
import Evergreen.V348.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V348.Id.Id Evergreen.V348.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V348.Point2d.Point2d Evergreen.V348.CssPixels.CssPixels Evergreen.V348.Touch.ScreenCoordinate
    , imageSize : Evergreen.V348.Coord.Coord Evergreen.V348.CssPixels.CssPixels
    , displayWidth : Float
    }


type Domain
    = Domain String


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
    | AttachedFile (Evergreen.V348.Id.Id Evergreen.V348.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V348.Id.Id Evergreen.V348.Id.StickerId)
    | CustomEmoji (Evergreen.V348.Id.Id Evergreen.V348.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V348.TimeInMinutes.TimeInMinutes


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V348.Discord.Id Evergreen.V348.Discord.CustomEmojiId
    , name : Evergreen.V348.CustomEmoji.EmojiName
    }
