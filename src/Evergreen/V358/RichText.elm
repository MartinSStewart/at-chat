module Evergreen.V358.RichText exposing (..)

import Evergreen.V358.Coord
import Evergreen.V358.CssPixels
import Evergreen.V358.CustomEmoji
import Evergreen.V358.Discord
import Evergreen.V358.FileStatus
import Evergreen.V358.Id
import Evergreen.V358.Point2d
import Evergreen.V358.TimeInMinutes
import Evergreen.V358.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V358.Id.Id Evergreen.V358.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V358.Point2d.Point2d Evergreen.V358.CssPixels.CssPixels Evergreen.V358.Touch.ScreenCoordinate
    , imageSize : Evergreen.V358.Coord.Coord Evergreen.V358.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V358.Id.Id Evergreen.V358.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V358.Id.Id Evergreen.V358.Id.StickerId)
    | CustomEmoji (Evergreen.V358.Id.Id Evergreen.V358.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V358.TimeInMinutes.TimeInMinutes


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V358.Discord.Id Evergreen.V358.Discord.CustomEmojiId
    , name : Evergreen.V358.CustomEmoji.EmojiName
    }
