module Evergreen.V295.RichText exposing (..)

import Evergreen.V295.Coord
import Evergreen.V295.CssPixels
import Evergreen.V295.CustomEmoji
import Evergreen.V295.Discord
import Evergreen.V295.FileStatus
import Evergreen.V295.Id
import Evergreen.V295.Point2d
import Evergreen.V295.Touch
import List.Nonempty
import String.Nonempty
import Url


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
    | AttachedFile (Evergreen.V295.Id.Id Evergreen.V295.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V295.Id.Id Evergreen.V295.Id.StickerId)
    | CustomEmoji (Evergreen.V295.Id.Id Evergreen.V295.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V295.Discord.Id Evergreen.V295.Discord.CustomEmojiId
    , name : Evergreen.V295.CustomEmoji.EmojiName
    }


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V295.Id.Id Evergreen.V295.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V295.Point2d.Point2d Evergreen.V295.CssPixels.CssPixels Evergreen.V295.Touch.ScreenCoordinate
    , imageSize : Evergreen.V295.Coord.Coord Evergreen.V295.CssPixels.CssPixels
    , displayWidth : Float
    }
