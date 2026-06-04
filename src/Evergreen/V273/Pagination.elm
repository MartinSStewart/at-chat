module Evergreen.V273.Pagination exposing (..)

import Array
import Evergreen.V273.Id
import SeqDict


type ItemId
    = ItemId Never


type PageId
    = PageId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V273.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V273.Id.Id PageId
    , previousPage : Evergreen.V273.Id.Id PageId
    , totalItems : Int
    }
