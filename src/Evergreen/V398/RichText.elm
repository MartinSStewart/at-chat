module Evergreen.V398.RichText exposing (..)

import Evergreen.V398.Coord
import Evergreen.V398.CssPixels
import Evergreen.V398.CustomEmoji
import Evergreen.V398.Discord
import Evergreen.V398.FileStatus
import Evergreen.V398.Id
import Evergreen.V398.Point2d
import Evergreen.V398.TimeInMinutes
import Evergreen.V398.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V398.Point2d.Point2d Evergreen.V398.CssPixels.CssPixels Evergreen.V398.Touch.ScreenCoordinate
    , imageSize : Evergreen.V398.Coord.Coord Evergreen.V398.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V398.Id.Id Evergreen.V398.Id.StickerId)
    | CustomEmoji (Evergreen.V398.Id.Id Evergreen.V398.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V398.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V398.Discord.Id Evergreen.V398.Discord.CustomEmojiId
    , name : Evergreen.V398.CustomEmoji.EmojiName
    }
