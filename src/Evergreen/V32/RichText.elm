module Evergreen.V32.RichText exposing (..)

import Evergreen.V32.Id
import List.Nonempty
import Url


type RichText
    = UserMention (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId)
    | NormalText Char String
    | Bold (List.Nonempty.Nonempty RichText)
    | Italic (List.Nonempty.Nonempty RichText)
    | Underline (List.Nonempty.Nonempty RichText)
    | Spoiler (List.Nonempty.Nonempty RichText)
    | Hyperlink Url.Protocol String
    | InlineCode Char String
