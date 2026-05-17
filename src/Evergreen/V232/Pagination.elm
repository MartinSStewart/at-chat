module Evergreen.V232.Pagination exposing (..)

import Array
import Evergreen.V232.Id
import SeqDict


type ItemId
    = ItemId Never


type PageId
    = PageId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V232.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V232.Id.Id PageId
    , previousPage : Evergreen.V232.Id.Id PageId
    , totalItems : Int
    }
