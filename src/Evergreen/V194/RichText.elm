module Evergreen.V194.RichText exposing (..)

import Evergreen.V194.FileStatus
import Evergreen.V194.Id
import List.Nonempty
import String.Nonempty
import Url


type Domain
    = Domain String


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
    | Hyperlink Url.Url
    | MarkdownLink String.Nonempty.NonemptyString Url.Url
    | InlineCode Char String
    | CodeBlock Language String
    | AttachedFile (Evergreen.V194.Id.Id Evergreen.V194.FileStatus.FileId)
    | EscapedChar EscapedChar
    | Sticker (Evergreen.V194.Id.Id Evergreen.V194.Id.StickerId)
