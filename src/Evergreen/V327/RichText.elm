module Evergreen.V327.RichText exposing (..)

import Evergreen.V327.Coord
import Evergreen.V327.CssPixels
import Evergreen.V327.CustomEmoji
import Evergreen.V327.Discord
import Evergreen.V327.FileStatus
import Evergreen.V327.Id
import Evergreen.V327.Point2d
import Evergreen.V327.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V327.Id.Id Evergreen.V327.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V327.Point2d.Point2d Evergreen.V327.CssPixels.CssPixels Evergreen.V327.Touch.ScreenCoordinate
    , imageSize : Evergreen.V327.Coord.Coord Evergreen.V327.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V327.Id.Id Evergreen.V327.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V327.Id.Id Evergreen.V327.Id.StickerId)
    | CustomEmoji (Evergreen.V327.Id.Id Evergreen.V327.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V327.Discord.Id Evergreen.V327.Discord.CustomEmojiId
    , name : Evergreen.V327.CustomEmoji.EmojiName
    }
