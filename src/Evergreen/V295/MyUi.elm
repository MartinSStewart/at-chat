module Evergreen.V295.MyUi exposing (..)

import Time


type Copied
    = CopiedText String
    | CopiedImage String


type alias LastCopy =
    { copiedAt : Time.Posix
    , copied : Copied
    }
