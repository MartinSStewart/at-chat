module Evergreen.V328.RichText exposing (..)

import Evergreen.V328.Coord
import Evergreen.V328.CssPixels
import Evergreen.V328.CustomEmoji
import Evergreen.V328.Discord
import Evergreen.V328.FileStatus
import Evergreen.V328.Id
import Evergreen.V328.Point2d
import Evergreen.V328.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V328.Id.Id Evergreen.V328.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V328.Point2d.Point2d Evergreen.V328.CssPixels.CssPixels Evergreen.V328.Touch.ScreenCoordinate
    , imageSize : Evergreen.V328.Coord.Coord Evergreen.V328.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V328.Id.Id Evergreen.V328.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V328.Id.Id Evergreen.V328.Id.StickerId)
    | CustomEmoji (Evergreen.V328.Id.Id Evergreen.V328.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V328.Discord.Id Evergreen.V328.Discord.CustomEmojiId
    , name : Evergreen.V328.CustomEmoji.EmojiName
    }
