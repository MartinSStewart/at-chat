module Evergreen.V363.RichText exposing (..)

import Evergreen.V363.Coord
import Evergreen.V363.CssPixels
import Evergreen.V363.CustomEmoji
import Evergreen.V363.Discord
import Evergreen.V363.FileStatus
import Evergreen.V363.Id
import Evergreen.V363.Point2d
import Evergreen.V363.TimeInMinutes
import Evergreen.V363.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V363.Point2d.Point2d Evergreen.V363.CssPixels.CssPixels Evergreen.V363.Touch.ScreenCoordinate
    , imageSize : Evergreen.V363.Coord.Coord Evergreen.V363.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V363.Id.Id Evergreen.V363.Id.StickerId)
    | CustomEmoji (Evergreen.V363.Id.Id Evergreen.V363.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Evergreen.V363.TimeInMinutes.TimeInMinutes


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V363.Discord.Id Evergreen.V363.Discord.CustomEmojiId
    , name : Evergreen.V363.CustomEmoji.EmojiName
    }
