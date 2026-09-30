module Evergreen.V395.RichText exposing (..)

import Evergreen.V395.Coord
import Evergreen.V395.CssPixels
import Evergreen.V395.CustomEmoji
import Evergreen.V395.Discord
import Evergreen.V395.FileStatus
import Evergreen.V395.Id
import Evergreen.V395.Point2d
import Evergreen.V395.TimeInMinutes
import Evergreen.V395.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V395.Point2d.Point2d Evergreen.V395.CssPixels.CssPixels Evergreen.V395.Touch.ScreenCoordinate
    , imageSize : Evergreen.V395.Coord.Coord Evergreen.V395.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V395.Id.Id Evergreen.V395.Id.StickerId)
    | CustomEmoji (Evergreen.V395.Id.Id Evergreen.V395.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V395.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V395.Discord.Id Evergreen.V395.Discord.CustomEmojiId
    , name : Evergreen.V395.CustomEmoji.EmojiName
    }
