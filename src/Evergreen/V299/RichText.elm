module Evergreen.V299.RichText exposing (..)

import Evergreen.V299.Coord
import Evergreen.V299.CssPixels
import Evergreen.V299.CustomEmoji
import Evergreen.V299.Discord
import Evergreen.V299.FileStatus
import Evergreen.V299.Id
import Evergreen.V299.Point2d
import Evergreen.V299.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V299.Id.Id Evergreen.V299.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V299.Point2d.Point2d Evergreen.V299.CssPixels.CssPixels Evergreen.V299.Touch.ScreenCoordinate
    , imageSize : Evergreen.V299.Coord.Coord Evergreen.V299.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V299.Id.Id Evergreen.V299.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V299.Id.Id Evergreen.V299.Id.StickerId)
    | CustomEmoji (Evergreen.V299.Id.Id Evergreen.V299.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V299.Discord.Id Evergreen.V299.Discord.CustomEmojiId
    , name : Evergreen.V299.CustomEmoji.EmojiName
    }
