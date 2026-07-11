module Evergreen.V316.Pagination exposing (..)

import Array
import Evergreen.V316.Id
import SeqDict


type PageId
    = PageId Never


type ItemId
    = ItemId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V316.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V316.Id.Id PageId
    , previousPage : Evergreen.V316.Id.Id PageId
    , totalItems : Int
    }
