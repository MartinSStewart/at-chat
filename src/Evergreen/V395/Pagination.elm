module Evergreen.V395.Pagination exposing (..)

import Array
import Evergreen.V395.Id
import SeqDict


type PageId
    = PageId Never


type ItemId
    = ItemId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V395.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V395.Id.Id PageId
    , previousPage : Evergreen.V395.Id.Id PageId
    , totalItems : Int
    }
