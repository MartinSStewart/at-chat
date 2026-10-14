module Evergreen.V406.RichText exposing (..)

import Evergreen.V406.Coord
import Evergreen.V406.CssPixels
import Evergreen.V406.CustomEmoji
import Evergreen.V406.Discord
import Evergreen.V406.FileStatus
import Evergreen.V406.Id
import Evergreen.V406.Point2d
import Evergreen.V406.TimeInMinutes
import Evergreen.V406.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V406.Point2d.Point2d Evergreen.V406.CssPixels.CssPixels Evergreen.V406.Touch.ScreenCoordinate
    , imageSize : Evergreen.V406.Coord.Coord Evergreen.V406.CssPixels.CssPixels
    , displayWidth : Float
    }


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


type RichText userId channelId
    = UserMention userId
    | ChannelMention channelId (Maybe (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId))
    | NormalText Char String
    | Bold (List.Nonempty.Nonempty (RichText userId channelId))
    | Italic (List.Nonempty.Nonempty (RichText userId channelId))
    | Underline (List.Nonempty.Nonempty (RichText userId channelId))
    | Strikethrough (List.Nonempty.Nonempty (RichText userId channelId))
    | Spoiler (List.Nonempty.Nonempty (RichText userId channelId))
    | BlockQuote HasLeadingLineBreak (List (RichText userId channelId))
    | Heading HeadingLevel HasLeadingLineBreak (List.Nonempty.Nonempty (RichText userId channelId))
    | Hyperlink Url.Url
    | MarkdownLink String.Nonempty.NonemptyString Url.Url
    | InlineCode Char String
    | CodeBlock Language String
    | AttachedFile (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V406.Id.Id Evergreen.V406.Id.StickerId)
    | CustomEmoji (Evergreen.V406.Id.Id Evergreen.V406.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V406.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V406.Discord.Id Evergreen.V406.Discord.CustomEmojiId
    , name : Evergreen.V406.CustomEmoji.EmojiName
    }
