module Evergreen.V407.Pagination exposing (..)

import Array
import Evergreen.V407.Id
import SeqDict


type PageId
    = PageId Never


type ItemId
    = ItemId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V407.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V407.Id.Id PageId
    , previousPage : Evergreen.V407.Id.Id PageId
    , totalItems : Int
    }
