module Evergreen.V354.RichText exposing (..)

import Evergreen.V354.Coord
import Evergreen.V354.CssPixels
import Evergreen.V354.CustomEmoji
import Evergreen.V354.Discord
import Evergreen.V354.FileStatus
import Evergreen.V354.Id
import Evergreen.V354.Point2d
import Evergreen.V354.TimeInMinutes
import Evergreen.V354.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V354.Id.Id Evergreen.V354.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V354.Point2d.Point2d Evergreen.V354.CssPixels.CssPixels Evergreen.V354.Touch.ScreenCoordinate
    , imageSize : Evergreen.V354.Coord.Coord Evergreen.V354.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V354.Id.Id Evergreen.V354.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V354.Id.Id Evergreen.V354.Id.StickerId)
    | CustomEmoji (Evergreen.V354.Id.Id Evergreen.V354.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V354.TimeInMinutes.TimeInMinutes


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V354.Discord.Id Evergreen.V354.Discord.CustomEmojiId
    , name : Evergreen.V354.CustomEmoji.EmojiName
    }
