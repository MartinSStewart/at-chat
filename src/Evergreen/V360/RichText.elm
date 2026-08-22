module Evergreen.V360.RichText exposing (..)

import Evergreen.V360.Coord
import Evergreen.V360.CssPixels
import Evergreen.V360.CustomEmoji
import Evergreen.V360.Discord
import Evergreen.V360.FileStatus
import Evergreen.V360.Id
import Evergreen.V360.Point2d
import Evergreen.V360.TimeInMinutes
import Evergreen.V360.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V360.Point2d.Point2d Evergreen.V360.CssPixels.CssPixels Evergreen.V360.Touch.ScreenCoordinate
    , imageSize : Evergreen.V360.Coord.Coord Evergreen.V360.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V360.Id.Id Evergreen.V360.Id.StickerId)
    | CustomEmoji (Evergreen.V360.Id.Id Evergreen.V360.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V360.TimeInMinutes.TimeInMinutes


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V360.Discord.Id Evergreen.V360.Discord.CustomEmojiId
    , name : Evergreen.V360.CustomEmoji.EmojiName
    }
