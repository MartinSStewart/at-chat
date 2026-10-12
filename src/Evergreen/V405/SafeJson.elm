module Evergreen.V405.SafeJson exposing (..)

import Dict
import Evergreen.V405.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V405.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
