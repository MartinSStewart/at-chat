module Evergreen.V290.RichText exposing (..)

import Evergreen.V290.Coord
import Evergreen.V290.CssPixels
import Evergreen.V290.CustomEmoji
import Evergreen.V290.Discord
import Evergreen.V290.FileStatus
import Evergreen.V290.Id
import Evergreen.V290.Point2d
import Evergreen.V290.Touch
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
    | AttachedFile (Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V290.Id.Id Evergreen.V290.Id.StickerId)
    | CustomEmoji (Evergreen.V290.Id.Id Evergreen.V290.Id.CustomEmojiId)


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V290.Discord.Id Evergreen.V290.Discord.CustomEmojiId
    , name : Evergreen.V290.CustomEmoji.EmojiName
    }


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V290.Point2d.Point2d Evergreen.V290.CssPixels.CssPixels Evergreen.V290.Touch.ScreenCoordinate
    , imageSize : Evergreen.V290.Coord.Coord Evergreen.V290.CssPixels.CssPixels
    , displayWidth : Float
    }
