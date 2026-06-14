module Evergreen.V289.RichText exposing (..)

import Evergreen.V289.Coord
import Evergreen.V289.CssPixels
import Evergreen.V289.CustomEmoji
import Evergreen.V289.Discord
import Evergreen.V289.FileStatus
import Evergreen.V289.Id
import Evergreen.V289.Point2d
import Evergreen.V289.Touch
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
    | AttachedFile (Evergreen.V289.Id.Id Evergreen.V289.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V289.Id.Id Evergreen.V289.Id.StickerId)
    | CustomEmoji (Evergreen.V289.Id.Id Evergreen.V289.Id.CustomEmojiId)


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V289.Discord.Id Evergreen.V289.Discord.CustomEmojiId
    , name : Evergreen.V289.CustomEmoji.EmojiName
    }


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V289.Id.Id Evergreen.V289.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V289.Point2d.Point2d Evergreen.V289.CssPixels.CssPixels Evergreen.V289.Touch.ScreenCoordinate
    , imageSize : Evergreen.V289.Coord.Coord Evergreen.V289.CssPixels.CssPixels
    , displayWidth : Float
    }
