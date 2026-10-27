module Evergreen.V417.RichText exposing (..)

import Evergreen.V417.Coord
import Evergreen.V417.CssPixels
import Evergreen.V417.CustomEmoji
import Evergreen.V417.Discord
import Evergreen.V417.FileStatus
import Evergreen.V417.Id
import Evergreen.V417.Point2d
import Evergreen.V417.TimeInMinutes
import Evergreen.V417.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V417.Point2d.Point2d Evergreen.V417.CssPixels.CssPixels Evergreen.V417.Touch.ScreenCoordinate
    , imageSize : Evergreen.V417.Coord.Coord Evergreen.V417.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V417.Id.Id Evergreen.V417.Id.StickerId)
    | CustomEmoji (Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V417.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V417.Discord.Id Evergreen.V417.Discord.CustomEmojiId
    , name : Evergreen.V417.CustomEmoji.EmojiName
    }
