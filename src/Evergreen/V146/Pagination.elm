module Evergreen.V146.Pagination exposing (..)

import Array
import Dict


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : Dict.Dict Int (PageStatus a)
    , currentPage : Int
    , totalPages : Int
    }
