module Evergreen.V422.SafeJson exposing (..)

import Dict
import Evergreen.V422.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V422.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
