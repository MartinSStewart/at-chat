module Evergreen.V311.RichText exposing (..)

import Evergreen.V311.Coord
import Evergreen.V311.CssPixels
import Evergreen.V311.CustomEmoji
import Evergreen.V311.Discord
import Evergreen.V311.FileStatus
import Evergreen.V311.Id
import Evergreen.V311.Point2d
import Evergreen.V311.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V311.Id.Id Evergreen.V311.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V311.Point2d.Point2d Evergreen.V311.CssPixels.CssPixels Evergreen.V311.Touch.ScreenCoordinate
    , imageSize : Evergreen.V311.Coord.Coord Evergreen.V311.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V311.Id.Id Evergreen.V311.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V311.Id.Id Evergreen.V311.Id.StickerId)
    | CustomEmoji (Evergreen.V311.Id.Id Evergreen.V311.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V311.Discord.Id Evergreen.V311.Discord.CustomEmojiId
    , name : Evergreen.V311.CustomEmoji.EmojiName
    }
