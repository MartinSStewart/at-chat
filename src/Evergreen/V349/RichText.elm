module Evergreen.V349.RichText exposing (..)

import Evergreen.V349.Coord
import Evergreen.V349.CssPixels
import Evergreen.V349.CustomEmoji
import Evergreen.V349.Discord
import Evergreen.V349.FileStatus
import Evergreen.V349.Id
import Evergreen.V349.Point2d
import Evergreen.V349.TimeInMinutes
import Evergreen.V349.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V349.Id.Id Evergreen.V349.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V349.Point2d.Point2d Evergreen.V349.CssPixels.CssPixels Evergreen.V349.Touch.ScreenCoordinate
    , imageSize : Evergreen.V349.Coord.Coord Evergreen.V349.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V349.Id.Id Evergreen.V349.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V349.Id.Id Evergreen.V349.Id.StickerId)
    | CustomEmoji (Evergreen.V349.Id.Id Evergreen.V349.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V349.TimeInMinutes.TimeInMinutes


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V349.Discord.Id Evergreen.V349.Discord.CustomEmojiId
    , name : Evergreen.V349.CustomEmoji.EmojiName
    }
