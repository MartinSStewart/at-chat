module Evergreen.V218.Pagination exposing (..)

import Array
import Evergreen.V218.Id
import SeqDict


type ItemId
    = ItemId Never


type PageId
    = PageId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V218.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V218.Id.Id PageId
    , previousPage : Evergreen.V218.Id.Id PageId
    , totalItems : Int
    }
