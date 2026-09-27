module Evergreen.V387.SafeJson exposing (..)

import Dict
import Evergreen.V387.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V387.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
