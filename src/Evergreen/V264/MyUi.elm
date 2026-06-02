module Evergreen.V264.MyUi exposing (..)

import Time


type alias LastCopy =
    { copiedAt : Time.Posix
    , copiedText : String
    }
