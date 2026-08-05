module Evergreen.V345.RichText exposing (..)

import Evergreen.V345.Coord
import Evergreen.V345.CssPixels
import Evergreen.V345.CustomEmoji
import Evergreen.V345.Discord
import Evergreen.V345.FileStatus
import Evergreen.V345.Id
import Evergreen.V345.Point2d
import Evergreen.V345.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V345.Id.Id Evergreen.V345.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V345.Point2d.Point2d Evergreen.V345.CssPixels.CssPixels Evergreen.V345.Touch.ScreenCoordinate
    , imageSize : Evergreen.V345.Coord.Coord Evergreen.V345.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V345.Id.Id Evergreen.V345.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V345.Id.Id Evergreen.V345.Id.StickerId)
    | CustomEmoji (Evergreen.V345.Id.Id Evergreen.V345.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V345.Discord.Id Evergreen.V345.Discord.CustomEmojiId
    , name : Evergreen.V345.CustomEmoji.EmojiName
    }
