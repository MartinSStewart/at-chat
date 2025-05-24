module Evergreen.V12.RichText exposing (..)

import Evergreen.V12.Id
import List.Nonempty
import Url


type RichText
    = UserMention (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
    | NormalText Char String
    | Bold (List.Nonempty.Nonempty RichText)
    | Italic (List.Nonempty.Nonempty RichText)
    | Underline (List.Nonempty.Nonempty RichText)
    | Spoiler (List.Nonempty.Nonempty RichText)
    | Hyperlink Url.Protocol String
    | InlineCode Char String
