module Evergreen.V339.Pagination exposing (..)

import Array
import Evergreen.V339.Id
import SeqDict


type PageId
    = PageId Never


type ItemId
    = ItemId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V339.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V339.Id.Id PageId
    , previousPage : Evergreen.V339.Id.Id PageId
    , totalItems : Int
    }
