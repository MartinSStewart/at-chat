module Evergreen.V346.RichText exposing (..)

import Effect.Time
import Evergreen.V346.Coord
import Evergreen.V346.CssPixels
import Evergreen.V346.CustomEmoji
import Evergreen.V346.Discord
import Evergreen.V346.FileStatus
import Evergreen.V346.Id
import Evergreen.V346.Point2d
import Evergreen.V346.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V346.Id.Id Evergreen.V346.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V346.Point2d.Point2d Evergreen.V346.CssPixels.CssPixels Evergreen.V346.Touch.ScreenCoordinate
    , imageSize : Evergreen.V346.Coord.Coord Evergreen.V346.CssPixels.CssPixels
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
    | AttachedFile (Evergreen.V346.Id.Id Evergreen.V346.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V346.Id.Id Evergreen.V346.Id.StickerId)
    | CustomEmoji (Evergreen.V346.Id.Id Evergreen.V346.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId)))
    | Timestamp Effect.Time.Posix


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V346.Discord.Id Evergreen.V346.Discord.CustomEmojiId
    , name : Evergreen.V346.CustomEmoji.EmojiName
    }
