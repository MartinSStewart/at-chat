module Evergreen.V426.SafeJson exposing (..)

import Dict
import Evergreen.V426.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V426.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
