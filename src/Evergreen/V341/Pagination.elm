module Evergreen.V341.Pagination exposing (..)

import Array
import Evergreen.V341.Id
import SeqDict


type PageId
    = PageId Never


type ItemId
    = ItemId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V341.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V341.Id.Id PageId
    , previousPage : Evergreen.V341.Id.Id PageId
    , totalItems : Int
    }
