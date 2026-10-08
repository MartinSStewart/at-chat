module Evergreen.V400.RichText exposing (..)

import Evergreen.V400.Coord
import Evergreen.V400.CssPixels
import Evergreen.V400.CustomEmoji
import Evergreen.V400.Discord
import Evergreen.V400.FileStatus
import Evergreen.V400.Id
import Evergreen.V400.Point2d
import Evergreen.V400.TimeInMinutes
import Evergreen.V400.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V400.Id.Id Evergreen.V400.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V400.Point2d.Point2d Evergreen.V400.CssPixels.CssPixels Evergreen.V400.Touch.ScreenCoordinate
    , imageSize : Evergreen.V400.Coord.Coord Evergreen.V400.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V400.Id.Id Evergreen.V400.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V400.Id.Id Evergreen.V400.Id.StickerId)
    | CustomEmoji (Evergreen.V400.Id.Id Evergreen.V400.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V400.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V400.Discord.Id Evergreen.V400.Discord.CustomEmojiId
    , name : Evergreen.V400.CustomEmoji.EmojiName
    }
