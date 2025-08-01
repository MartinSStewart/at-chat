module Evergreen.V14.RichText exposing (..)

import Evergreen.V14.Id
import List.Nonempty
import String.Nonempty
import Url


type Language
    = Language String.Nonempty.NonemptyString
    | None


type RichText
    = UserMention (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
    | NormalText Char String
    | Bold (List.Nonempty.Nonempty RichText)
    | Italic (List.Nonempty.Nonempty RichText)
    | Underline (List.Nonempty.Nonempty RichText)
    | Strikethrough (List.Nonempty.Nonempty RichText)
    | Spoiler (List.Nonempty.Nonempty RichText)
    | Hyperlink Url.Protocol String
    | InlineCode Char String
    | CodeBlock Language String
