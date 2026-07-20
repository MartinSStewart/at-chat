module Evergreen.V332.Pagination exposing (..)

import Array
import Evergreen.V332.Id
import SeqDict


type PageId
    = PageId Never


type ItemId
    = ItemId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V332.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V332.Id.Id PageId
    , previousPage : Evergreen.V332.Id.Id PageId
    , totalItems : Int
    }
