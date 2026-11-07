module Evergreen.V421.RichText exposing (..)

import Evergreen.V421.Coord
import Evergreen.V421.CssPixels
import Evergreen.V421.CustomEmoji
import Evergreen.V421.Discord
import Evergreen.V421.FileStatus
import Evergreen.V421.Id
import Evergreen.V421.Point2d
import Evergreen.V421.TimeInMinutes
import Evergreen.V421.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V421.Point2d.Point2d Evergreen.V421.CssPixels.CssPixels Evergreen.V421.Touch.ScreenCoordinate
    , imageSize : Evergreen.V421.Coord.Coord Evergreen.V421.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V421.Id.Id Evergreen.V421.Id.StickerId)
    | CustomEmoji (Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V421.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V421.Discord.Id Evergreen.V421.Discord.CustomEmojiId
    , name : Evergreen.V421.CustomEmoji.EmojiName
    }
