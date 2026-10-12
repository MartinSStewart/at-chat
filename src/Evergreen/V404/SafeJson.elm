module Evergreen.V404.SafeJson exposing (..)

import Dict
import Evergreen.V404.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V404.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
