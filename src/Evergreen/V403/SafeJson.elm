module Evergreen.V403.SafeJson exposing (..)

import Dict
import Evergreen.V403.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V403.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
