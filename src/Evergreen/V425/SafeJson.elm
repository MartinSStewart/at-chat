module Evergreen.V425.SafeJson exposing (..)

import Dict
import Evergreen.V425.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V425.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
