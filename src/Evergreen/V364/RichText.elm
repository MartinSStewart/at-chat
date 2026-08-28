module Evergreen.V364.RichText exposing (..)

import Evergreen.V364.Coord
import Evergreen.V364.CssPixels
import Evergreen.V364.CustomEmoji
import Evergreen.V364.Discord
import Evergreen.V364.FileStatus
import Evergreen.V364.Id
import Evergreen.V364.Point2d
import Evergreen.V364.TimeInMinutes
import Evergreen.V364.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V364.Point2d.Point2d Evergreen.V364.CssPixels.CssPixels Evergreen.V364.Touch.ScreenCoordinate
    , imageSize : Evergreen.V364.Coord.Coord Evergreen.V364.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V364.Id.Id Evergreen.V364.Id.StickerId)
    | CustomEmoji (Evergreen.V364.Id.Id Evergreen.V364.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V364.TimeInMinutes.TimeInMinutes


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V364.Discord.Id Evergreen.V364.Discord.CustomEmojiId
    , name : Evergreen.V364.CustomEmoji.EmojiName
    }
