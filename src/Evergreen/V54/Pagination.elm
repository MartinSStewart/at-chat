module Evergreen.V54.Pagination exposing (..)

import Array
import Dict


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : Dict.Dict Int (PageStatus a)
    , currentPage : Int
    , totalPages : Maybe Int
    }


type ToBackend
    = PageRequest Int


type ToFrontend a
    = PageResponse
        { pageIndex : Int
        , totalPages : Int
        , pageData : Array.Array a
        }
