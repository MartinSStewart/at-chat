module Evergreen.V147.Pagination exposing (..)

import Array
import Evergreen.V147.Id
import SeqDict


type ItemId
    = ItemId Never


type PageId
    = PageId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V147.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V147.Id.Id PageId
    , previousPage : Evergreen.V147.Id.Id PageId
    , totalPages : Int
    }
