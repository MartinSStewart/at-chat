module Evergreen.V243.MyUi exposing (..)

import Time


type alias LastCopy =
    { copiedAt : Time.Posix
    , copiedText : String
    }
