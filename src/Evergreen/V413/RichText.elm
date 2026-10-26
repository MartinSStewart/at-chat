module Evergreen.V413.RichText exposing (..)

import Evergreen.V413.Coord
import Evergreen.V413.CssPixels
import Evergreen.V413.CustomEmoji
import Evergreen.V413.Discord
import Evergreen.V413.FileStatus
import Evergreen.V413.Id
import Evergreen.V413.Point2d
import Evergreen.V413.TimeInMinutes
import Evergreen.V413.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V413.Point2d.Point2d Evergreen.V413.CssPixels.CssPixels Evergreen.V413.Touch.ScreenCoordinate
    , imageSize : Evergreen.V413.Coord.Coord Evergreen.V413.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V413.Id.Id Evergreen.V413.Id.StickerId)
    | CustomEmoji (Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V413.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V413.Discord.Id Evergreen.V413.Discord.CustomEmojiId
    , name : Evergreen.V413.CustomEmoji.EmojiName
    }
