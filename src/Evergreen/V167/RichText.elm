module Evergreen.V167.RichText exposing (..)

import Evergreen.V167.FileStatus
import Evergreen.V167.Id
import List.Nonempty
import String.Nonempty
import Url


type Domain
    = Domain String


type Language
    = Language String.Nonempty.NonemptyString
    | NoLanguage


type Modifiers
    = IsBold
    | IsItalic
    | IsUnderlined
    | IsStrikethrough
    | IsSpoilered


type EscapedChar
    = EscapedModifier Modifiers
    | EscapedSquareBracket
    | EscapedBackslash
    | EscapedBacktick
    | EscapedAtSymbol


type RichText userId
    = UserMention userId
    | NormalText Char String
    | Bold (List.Nonempty.Nonempty (RichText userId))
    | Italic (List.Nonempty.Nonempty (RichText userId))
    | Underline (List.Nonempty.Nonempty (RichText userId))
    | Strikethrough (List.Nonempty.Nonempty (RichText userId))
    | Spoiler (List.Nonempty.Nonempty (RichText userId))
    | Hyperlink Url.Url
    | InlineCode Char String
    | CodeBlock Language String
    | AttachedFile (Evergreen.V167.Id.Id Evergreen.V167.FileStatus.FileId)
    | EscapedChar EscapedChar
