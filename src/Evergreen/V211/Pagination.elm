module Evergreen.V211.Pagination exposing (..)

import Array
import Evergreen.V211.Id
import SeqDict


type ItemId
    = ItemId Never


type PageId
    = PageId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V211.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V211.Id.Id PageId
    , previousPage : Evergreen.V211.Id.Id PageId
    , totalItems : Int
    }
