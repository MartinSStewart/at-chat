module Evergreen.V323.Pagination exposing (..)

import Array
import Evergreen.V323.Id
import SeqDict


type PageId
    = PageId Never


type ItemId
    = ItemId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V323.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V323.Id.Id PageId
    , previousPage : Evergreen.V323.Id.Id PageId
    , totalItems : Int
    }
