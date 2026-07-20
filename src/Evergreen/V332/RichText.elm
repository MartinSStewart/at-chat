module Evergreen.V332.RichText exposing (..)

import Evergreen.V332.Coord
import Evergreen.V332.CssPixels
import Evergreen.V332.CustomEmoji
import Evergreen.V332.Discord
import Evergreen.V332.FileStatus
import Evergreen.V332.Id
import Evergreen.V332.Point2d
import Evergreen.V332.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V332.Id.Id Evergreen.V332.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V332.Point2d.Point2d Evergreen.V332.CssPixels.CssPixels Evergreen.V332.Touch.ScreenCoordinate
    , imageSize : Evergreen.V332.Coord.Coord Evergreen.V332.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V332.Id.Id Evergreen.V332.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V332.Id.Id Evergreen.V332.Id.StickerId)
    | CustomEmoji (Evergreen.V332.Id.Id Evergreen.V332.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V332.Discord.Id Evergreen.V332.Discord.CustomEmojiId
    , name : Evergreen.V332.CustomEmoji.EmojiName
    }
