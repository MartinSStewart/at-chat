module Evergreen.V387.RichText exposing (..)

import Evergreen.V387.Coord
import Evergreen.V387.CssPixels
import Evergreen.V387.CustomEmoji
import Evergreen.V387.Discord
import Evergreen.V387.FileStatus
import Evergreen.V387.Id
import Evergreen.V387.Point2d
import Evergreen.V387.TimeInMinutes
import Evergreen.V387.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V387.Point2d.Point2d Evergreen.V387.CssPixels.CssPixels Evergreen.V387.Touch.ScreenCoordinate
    , imageSize : Evergreen.V387.Coord.Coord Evergreen.V387.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V387.Id.Id Evergreen.V387.Id.StickerId)
    | CustomEmoji (Evergreen.V387.Id.Id Evergreen.V387.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V387.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V387.Discord.Id Evergreen.V387.Discord.CustomEmojiId
    , name : Evergreen.V387.CustomEmoji.EmojiName
    }
