module Evergreen.V408.SafeJson exposing (..)

import Dict
import Evergreen.V408.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V408.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
