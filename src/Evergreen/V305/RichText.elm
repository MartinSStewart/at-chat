module Evergreen.V305.RichText exposing (..)

import Evergreen.V305.Coord
import Evergreen.V305.CssPixels
import Evergreen.V305.CustomEmoji
import Evergreen.V305.Discord
import Evergreen.V305.FileStatus
import Evergreen.V305.Id
import Evergreen.V305.Point2d
import Evergreen.V305.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V305.Id.Id Evergreen.V305.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V305.Point2d.Point2d Evergreen.V305.CssPixels.CssPixels Evergreen.V305.Touch.ScreenCoordinate
    , imageSize : Evergreen.V305.Coord.Coord Evergreen.V305.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V305.Id.Id Evergreen.V305.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V305.Id.Id Evergreen.V305.Id.StickerId)
    | CustomEmoji (Evergreen.V305.Id.Id Evergreen.V305.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V305.Discord.Id Evergreen.V305.Discord.CustomEmojiId
    , name : Evergreen.V305.CustomEmoji.EmojiName
    }
