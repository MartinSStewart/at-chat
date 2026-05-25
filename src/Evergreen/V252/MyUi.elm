module Evergreen.V252.MyUi exposing (..)

import Time


type alias LastCopy =
    { copiedAt : Time.Posix
    , copiedText : String
    }
