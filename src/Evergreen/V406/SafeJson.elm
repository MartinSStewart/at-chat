module Evergreen.V406.SafeJson exposing (..)

import Dict
import Evergreen.V406.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V406.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
