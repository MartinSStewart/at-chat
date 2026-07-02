module Evergreen.V298.RichText exposing (..)

import Evergreen.V298.Coord
import Evergreen.V298.CssPixels
import Evergreen.V298.CustomEmoji
import Evergreen.V298.Discord
import Evergreen.V298.FileStatus
import Evergreen.V298.Id
import Evergreen.V298.Point2d
import Evergreen.V298.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V298.Id.Id Evergreen.V298.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V298.Point2d.Point2d Evergreen.V298.CssPixels.CssPixels Evergreen.V298.Touch.ScreenCoordinate
    , imageSize : Evergreen.V298.Coord.Coord Evergreen.V298.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V298.Id.Id Evergreen.V298.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V298.Id.Id Evergreen.V298.Id.StickerId)
    | CustomEmoji (Evergreen.V298.Id.Id Evergreen.V298.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V298.Discord.Id Evergreen.V298.Discord.CustomEmojiId
    , name : Evergreen.V298.CustomEmoji.EmojiName
    }
