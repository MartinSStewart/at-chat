module Evergreen.V343.Pagination exposing (..)

import Array
import Evergreen.V343.Id
import SeqDict


type PageId
    = PageId Never


type ItemId
    = ItemId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V343.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V343.Id.Id PageId
    , previousPage : Evergreen.V343.Id.Id PageId
    , totalItems : Int
    }
