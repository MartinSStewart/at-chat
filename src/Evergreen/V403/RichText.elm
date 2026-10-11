module Evergreen.V403.RichText exposing (..)

import Evergreen.V403.Coord
import Evergreen.V403.CssPixels
import Evergreen.V403.CustomEmoji
import Evergreen.V403.Discord
import Evergreen.V403.FileStatus
import Evergreen.V403.Id
import Evergreen.V403.Point2d
import Evergreen.V403.TimeInMinutes
import Evergreen.V403.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V403.Point2d.Point2d Evergreen.V403.CssPixels.CssPixels Evergreen.V403.Touch.ScreenCoordinate
    , imageSize : Evergreen.V403.Coord.Coord Evergreen.V403.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V403.Id.Id Evergreen.V403.Id.StickerId)
    | CustomEmoji (Evergreen.V403.Id.Id Evergreen.V403.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V403.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V403.Discord.Id Evergreen.V403.Discord.CustomEmojiId
    , name : Evergreen.V403.CustomEmoji.EmojiName
    }
