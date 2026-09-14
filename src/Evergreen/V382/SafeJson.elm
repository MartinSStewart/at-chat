module Evergreen.V382.SafeJson exposing (..)

import Dict
import Evergreen.V382.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V382.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
