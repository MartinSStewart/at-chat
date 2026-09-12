module Evergreen.V379.SafeJson exposing (..)

import Dict
import Evergreen.V379.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V379.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
