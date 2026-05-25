module Evergreen.V247.MyUi exposing (..)

import Time


type alias LastCopy =
    { copiedAt : Time.Posix
    , copiedText : String
    }
