module Evergreen.V336.RichText exposing (..)

import Evergreen.V336.Coord
import Evergreen.V336.CssPixels
import Evergreen.V336.CustomEmoji
import Evergreen.V336.Discord
import Evergreen.V336.FileStatus
import Evergreen.V336.Id
import Evergreen.V336.Point2d
import Evergreen.V336.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V336.Id.Id Evergreen.V336.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V336.Point2d.Point2d Evergreen.V336.CssPixels.CssPixels Evergreen.V336.Touch.ScreenCoordinate
    , imageSize : Evergreen.V336.Coord.Coord Evergreen.V336.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V336.Id.Id Evergreen.V336.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V336.Id.Id Evergreen.V336.Id.StickerId)
    | CustomEmoji (Evergreen.V336.Id.Id Evergreen.V336.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V336.Discord.Id Evergreen.V336.Discord.CustomEmojiId
    , name : Evergreen.V336.CustomEmoji.EmojiName
    }
