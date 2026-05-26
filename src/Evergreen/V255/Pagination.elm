module Evergreen.V255.Pagination exposing (..)

import Array
import Evergreen.V255.Id
import SeqDict


type ItemId
    = ItemId Never


type PageId
    = PageId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V255.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V255.Id.Id PageId
    , previousPage : Evergreen.V255.Id.Id PageId
    , totalItems : Int
    }
