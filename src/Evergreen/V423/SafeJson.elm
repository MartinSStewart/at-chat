module Evergreen.V423.SafeJson exposing (..)

import Dict
import Evergreen.V423.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V423.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
