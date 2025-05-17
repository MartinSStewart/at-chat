module Evergreen.V1.RichText exposing (..)

import Evergreen.V1.Id
import List.Nonempty


type RichText
    = UserMention (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId)
    | NormalText Char String
    | Bold (List.Nonempty.Nonempty RichText)
    | Italic (List.Nonempty.Nonempty RichText)
    | Underline (List.Nonempty.Nonempty RichText)
    | Spoiler (List.Nonempty.Nonempty RichText)
