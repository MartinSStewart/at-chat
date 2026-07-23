module Evergreen.V333.RichText exposing (..)

import Evergreen.V333.Coord
import Evergreen.V333.CssPixels
import Evergreen.V333.CustomEmoji
import Evergreen.V333.Discord
import Evergreen.V333.FileStatus
import Evergreen.V333.Id
import Evergreen.V333.Point2d
import Evergreen.V333.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V333.Id.Id Evergreen.V333.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V333.Point2d.Point2d Evergreen.V333.CssPixels.CssPixels Evergreen.V333.Touch.ScreenCoordinate
    , imageSize : Evergreen.V333.Coord.Coord Evergreen.V333.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V333.Id.Id Evergreen.V333.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V333.Id.Id Evergreen.V333.Id.StickerId)
    | CustomEmoji (Evergreen.V333.Id.Id Evergreen.V333.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V333.Discord.Id Evergreen.V333.Discord.CustomEmojiId
    , name : Evergreen.V333.CustomEmoji.EmojiName
    }
