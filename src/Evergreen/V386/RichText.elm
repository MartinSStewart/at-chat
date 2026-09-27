module Evergreen.V386.RichText exposing (..)

import Evergreen.V386.Coord
import Evergreen.V386.CssPixels
import Evergreen.V386.CustomEmoji
import Evergreen.V386.Discord
import Evergreen.V386.FileStatus
import Evergreen.V386.Id
import Evergreen.V386.Point2d
import Evergreen.V386.TimeInMinutes
import Evergreen.V386.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V386.Point2d.Point2d Evergreen.V386.CssPixels.CssPixels Evergreen.V386.Touch.ScreenCoordinate
    , imageSize : Evergreen.V386.Coord.Coord Evergreen.V386.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V386.Id.Id Evergreen.V386.Id.StickerId)
    | CustomEmoji (Evergreen.V386.Id.Id Evergreen.V386.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V386.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V386.Discord.Id Evergreen.V386.Discord.CustomEmojiId
    , name : Evergreen.V386.CustomEmoji.EmojiName
    }
