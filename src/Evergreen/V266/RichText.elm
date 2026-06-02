module Evergreen.V266.RichText exposing (..)

import Evergreen.V266.CustomEmoji
import Evergreen.V266.Discord
import Evergreen.V266.FileStatus
import Evergreen.V266.Id
import List.Nonempty
import String.Nonempty
import Url


type Domain
    = Domain String


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


type RichText userId
    = UserMention userId
    | NormalText Char String
    | Bold (List.Nonempty.Nonempty (RichText userId))
    | Italic (List.Nonempty.Nonempty (RichText userId))
    | Underline (List.Nonempty.Nonempty (RichText userId))
    | Strikethrough (List.Nonempty.Nonempty (RichText userId))
    | Spoiler (List.Nonempty.Nonempty (RichText userId))
    | BlockQuote HasLeadingLineBreak (List (RichText userId))
    | Heading HeadingLevel HasLeadingLineBreak (List.Nonempty.Nonempty (RichText userId))
    | Hyperlink Url.Url
    | MarkdownLink String.Nonempty.NonemptyString Url.Url
    | InlineCode Char String
    | CodeBlock Language String
    | AttachedFile (Evergreen.V266.Id.Id Evergreen.V266.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V266.Id.Id Evergreen.V266.Id.StickerId)
    | CustomEmoji (Evergreen.V266.Id.Id Evergreen.V266.Id.CustomEmojiId)


type alias DiscordCustomEmojiIdAndName =
    { isAnimated : Bool
    , id : Evergreen.V266.Discord.Id Evergreen.V266.Discord.CustomEmojiId
    , name : Evergreen.V266.CustomEmoji.EmojiName
    }
