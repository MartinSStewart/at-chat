module Evergreen.V293.RichText exposing (..)

import Evergreen.V293.Coord
import Evergreen.V293.CssPixels
import Evergreen.V293.CustomEmoji
import Evergreen.V293.Discord
import Evergreen.V293.FileStatus
import Evergreen.V293.Id
import Evergreen.V293.Point2d
import Evergreen.V293.Touch
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
    | AttachedFile (Evergreen.V293.Id.Id Evergreen.V293.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V293.Id.Id Evergreen.V293.Id.StickerId)
    | CustomEmoji (Evergreen.V293.Id.Id Evergreen.V293.Id.CustomEmojiId)


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V293.Discord.Id Evergreen.V293.Discord.CustomEmojiId
    , name : Evergreen.V293.CustomEmoji.EmojiName
    }


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V293.Id.Id Evergreen.V293.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V293.Point2d.Point2d Evergreen.V293.CssPixels.CssPixels Evergreen.V293.Touch.ScreenCoordinate
    , imageSize : Evergreen.V293.Coord.Coord Evergreen.V293.CssPixels.CssPixels
    , displayWidth : Float
    }
