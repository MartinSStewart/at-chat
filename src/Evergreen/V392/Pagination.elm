module Evergreen.V392.Pagination exposing (..)

import Array
import Evergreen.V392.Id
import SeqDict


type PageId
    = PageId Never


type ItemId
    = ItemId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V392.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V392.Id.Id PageId
    , previousPage : Evergreen.V392.Id.Id PageId
    , totalItems : Int
    }
