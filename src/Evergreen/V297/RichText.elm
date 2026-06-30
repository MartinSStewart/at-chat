module Evergreen.V297.RichText exposing (..)

import Evergreen.V297.Coord
import Evergreen.V297.CssPixels
import Evergreen.V297.CustomEmoji
import Evergreen.V297.Discord
import Evergreen.V297.FileStatus
import Evergreen.V297.Id
import Evergreen.V297.Point2d
import Evergreen.V297.Touch
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
    | AttachedFile (Evergreen.V297.Id.Id Evergreen.V297.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V297.Id.Id Evergreen.V297.Id.StickerId)
    | CustomEmoji (Evergreen.V297.Id.Id Evergreen.V297.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V297.Discord.Id Evergreen.V297.Discord.CustomEmojiId
    , name : Evergreen.V297.CustomEmoji.EmojiName
    }


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V297.Id.Id Evergreen.V297.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V297.Point2d.Point2d Evergreen.V297.CssPixels.CssPixels Evergreen.V297.Touch.ScreenCoordinate
    , imageSize : Evergreen.V297.Coord.Coord Evergreen.V297.CssPixels.CssPixels
    , displayWidth : Float
    }
