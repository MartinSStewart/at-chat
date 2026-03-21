module Evergreen.V163.Pagination exposing (..)

import Array
import Evergreen.V163.Id
import SeqDict


type ItemId
    = ItemId Never


type PageId
    = PageId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V163.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V163.Id.Id PageId
    , previousPage : Evergreen.V163.Id.Id PageId
    , totalItems : Int
    }
