module Evergreen.V402.RichText exposing (..)

import Evergreen.V402.Coord
import Evergreen.V402.CssPixels
import Evergreen.V402.CustomEmoji
import Evergreen.V402.Discord
import Evergreen.V402.FileStatus
import Evergreen.V402.Id
import Evergreen.V402.Point2d
import Evergreen.V402.TimeInMinutes
import Evergreen.V402.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V402.Point2d.Point2d Evergreen.V402.CssPixels.CssPixels Evergreen.V402.Touch.ScreenCoordinate
    , imageSize : Evergreen.V402.Coord.Coord Evergreen.V402.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V402.Id.Id Evergreen.V402.Id.StickerId)
    | CustomEmoji (Evergreen.V402.Id.Id Evergreen.V402.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V402.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V402.Discord.Id Evergreen.V402.Discord.CustomEmojiId
    , name : Evergreen.V402.CustomEmoji.EmojiName
    }
