module Evergreen.V315.Pagination exposing (..)

import Array
import Evergreen.V315.Id
import SeqDict


type PageId
    = PageId Never


type ItemId
    = ItemId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V315.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V315.Id.Id PageId
    , previousPage : Evergreen.V315.Id.Id PageId
    , totalItems : Int
    }
