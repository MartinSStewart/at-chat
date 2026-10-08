module Evergreen.V401.Pagination exposing (..)

import Array
import Evergreen.V401.Id
import SeqDict


type PageId
    = PageId Never


type ItemId
    = ItemId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V401.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V401.Id.Id PageId
    , previousPage : Evergreen.V401.Id.Id PageId
    , totalItems : Int
    }
