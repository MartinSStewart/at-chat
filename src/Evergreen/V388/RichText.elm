module Evergreen.V388.RichText exposing (..)

import Evergreen.V388.Coord
import Evergreen.V388.CssPixels
import Evergreen.V388.CustomEmoji
import Evergreen.V388.Discord
import Evergreen.V388.FileStatus
import Evergreen.V388.Id
import Evergreen.V388.Point2d
import Evergreen.V388.TimeInMinutes
import Evergreen.V388.Touch
import List.Nonempty
import String.Nonempty
import Url


type PressedImageId
    = PressedAttachedFileImage (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId)
    | PressedEmbedImage Int


type alias PressedImageData =
    { imageId : PressedImageId
    , fileUrl : String
    , position : Evergreen.V388.Point2d.Point2d Evergreen.V388.CssPixels.CssPixels Evergreen.V388.Touch.ScreenCoordinate
    , imageSize : Evergreen.V388.Coord.Coord Evergreen.V388.CssPixels.CssPixels
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
    | ChannelMention channelId (Maybe (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId))
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
    | AttachedFile (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V388.Id.Id Evergreen.V388.Id.StickerId)
    | CustomEmoji (Evergreen.V388.Id.Id Evergreen.V388.Id.CustomEmojiId)
    | BulletPoint HasLeadingLineBreak (List.Nonempty.Nonempty (List (RichText userId channelId)))
    | Timestamp Evergreen.V388.TimeInMinutes.TimeInMinutes


type Domain
    = Domain String


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V388.Discord.Id Evergreen.V388.Discord.CustomEmojiId
    , name : Evergreen.V388.CustomEmoji.EmojiName
    }
