module Evergreen.V271.MyUi exposing (..)

import Time


type Copied
    = CopiedText String
    | CopiedImage String


type alias LastCopy =
    { copiedAt : Time.Posix
    , copied : Copied
    }
