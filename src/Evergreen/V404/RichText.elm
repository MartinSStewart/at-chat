module Evergreen.V404.RichText exposing (..)

import Evergreen.V404.Coord
import Evergreen.V404.CssPixels
import Evergreen.V404.CustomEmoji
import Evergreen.V404.Discord
import Evergreen.V404.FileStatus
import Evergreen.V404.Id
import Evergreen.V404.Point2d
import Evergreen.V404.TimeInMinutes
import Evergreen.V404.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V404.Id.Id Evergreen.V404.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V404.Point2d.Point2d Evergreen.V404.CssPixels.CssPixels Evergreen.V404.Touch.ScreenCoordinate
    , imageSize : Evergreen.V404.Coord.Coord Evergreen.V404.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V404.Id.Id Evergreen.V404.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V404.Id.Id Evergreen.V404.Id.StickerId)
    | CustomEmoji (Evergreen.V404.Id.Id Evergreen.V404.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V404.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V404.Discord.Id Evergreen.V404.Discord.CustomEmojiId
    , name : Evergreen.V404.CustomEmoji.EmojiName
    }
