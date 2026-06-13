module Evergreen.V288.RichText exposing (..)

import Evergreen.V288.Coord
import Evergreen.V288.CssPixels
import Evergreen.V288.CustomEmoji
import Evergreen.V288.Discord
import Evergreen.V288.FileStatus
import Evergreen.V288.Id
import Evergreen.V288.Point2d
import Evergreen.V288.Touch
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
    | AttachedFile (Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V288.Id.Id Evergreen.V288.Id.StickerId)
    | CustomEmoji (Evergreen.V288.Id.Id Evergreen.V288.Id.CustomEmojiId)


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V288.Discord.Id Evergreen.V288.Discord.CustomEmojiId
    , name : Evergreen.V288.CustomEmoji.EmojiName
    }


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V288.Point2d.Point2d Evergreen.V288.CssPixels.CssPixels Evergreen.V288.Touch.ScreenCoordinate
    , imageSize : Evergreen.V288.Coord.Coord Evergreen.V288.CssPixels.CssPixels
    , displayWidth : Float
    }
