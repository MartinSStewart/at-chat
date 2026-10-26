module Evergreen.V414.SafeJson exposing (..)

import Dict
import Evergreen.V414.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V414.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
