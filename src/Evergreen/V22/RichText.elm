module Evergreen.V22.RichText exposing (..)

import Evergreen.V22.Id
import List.Nonempty
import Url


type RichText
    = UserMention (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId)
    | NormalText Char String
    | Bold (List.Nonempty.Nonempty RichText)
    | Italic (List.Nonempty.Nonempty RichText)
    | Underline (List.Nonempty.Nonempty RichText)
    | Spoiler (List.Nonempty.Nonempty RichText)
    | Hyperlink Url.Protocol String
    | InlineCode Char String
