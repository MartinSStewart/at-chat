module Evergreen.V414.RichText exposing (..)

import Evergreen.V414.Coord
import Evergreen.V414.CssPixels
import Evergreen.V414.CustomEmoji
import Evergreen.V414.Discord
import Evergreen.V414.FileStatus
import Evergreen.V414.Id
import Evergreen.V414.Point2d
import Evergreen.V414.TimeInMinutes
import Evergreen.V414.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V414.Id.Id Evergreen.V414.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V414.Point2d.Point2d Evergreen.V414.CssPixels.CssPixels Evergreen.V414.Touch.ScreenCoordinate
    , imageSize : Evergreen.V414.Coord.Coord Evergreen.V414.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V414.Id.Id Evergreen.V414.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V414.Id.Id Evergreen.V414.Id.StickerId)
    | CustomEmoji (Evergreen.V414.Id.Id Evergreen.V414.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V414.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V414.Discord.Id Evergreen.V414.Discord.CustomEmojiId
    , name : Evergreen.V414.CustomEmoji.EmojiName
    }
