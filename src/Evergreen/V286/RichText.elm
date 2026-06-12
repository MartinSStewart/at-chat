module Evergreen.V286.RichText exposing (..)

import Evergreen.V286.Coord
import Evergreen.V286.CssPixels
import Evergreen.V286.CustomEmoji
import Evergreen.V286.Discord
import Evergreen.V286.FileStatus
import Evergreen.V286.Id
import Evergreen.V286.Point2d
import Evergreen.V286.Touch
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
    | AttachedFile (Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V286.Id.Id Evergreen.V286.Id.StickerId)
    | CustomEmoji (Evergreen.V286.Id.Id Evergreen.V286.Id.CustomEmojiId)


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V286.Discord.Id Evergreen.V286.Discord.CustomEmojiId
    , name : Evergreen.V286.CustomEmoji.EmojiName
    }


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V286.Point2d.Point2d Evergreen.V286.CssPixels.CssPixels Evergreen.V286.Touch.ScreenCoordinate
    , imageSize : Evergreen.V286.Coord.Coord Evergreen.V286.CssPixels.CssPixels
    }
