module Evergreen.V309.RichText exposing (..)

import Evergreen.V309.Coord
import Evergreen.V309.CssPixels
import Evergreen.V309.CustomEmoji
import Evergreen.V309.Discord
import Evergreen.V309.FileStatus
import Evergreen.V309.Id
import Evergreen.V309.Point2d
import Evergreen.V309.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V309.Id.Id Evergreen.V309.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V309.Point2d.Point2d Evergreen.V309.CssPixels.CssPixels Evergreen.V309.Touch.ScreenCoordinate
    , imageSize : Evergreen.V309.Coord.Coord Evergreen.V309.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V309.Id.Id Evergreen.V309.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V309.Id.Id Evergreen.V309.Id.StickerId)
    | CustomEmoji (Evergreen.V309.Id.Id Evergreen.V309.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V309.Discord.Id Evergreen.V309.Discord.CustomEmojiId
    , name : Evergreen.V309.CustomEmoji.EmojiName
    }
