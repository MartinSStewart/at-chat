module Evergreen.V417.SafeJson exposing (..)

import Dict
import Evergreen.V417.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V417.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
