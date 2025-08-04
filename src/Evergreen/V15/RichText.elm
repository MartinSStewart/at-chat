module Evergreen.V15.RichText exposing (..)

import Evergreen.V15.Id
import List.Nonempty
import String.Nonempty
import Url


type Language
    = Language String.Nonempty.NonemptyString
    | None


type RichText
    = UserMention (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
    | NormalText Char String
    | Bold (List.Nonempty.Nonempty RichText)
    | Italic (List.Nonempty.Nonempty RichText)
    | Underline (List.Nonempty.Nonempty RichText)
    | Strikethrough (List.Nonempty.Nonempty RichText)
    | Spoiler (List.Nonempty.Nonempty RichText)
    | Hyperlink Url.Protocol String
    | InlineCode Char String
    | CodeBlock Language String
