module Evergreen.V409.SafeJson exposing (..)

import Dict
import Evergreen.V409.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V409.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
