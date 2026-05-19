module Evergreen.V240.Pagination exposing (..)

import Array
import Evergreen.V240.Id
import SeqDict


type ItemId
    = ItemId Never


type PageId
    = PageId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V240.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V240.Id.Id PageId
    , previousPage : Evergreen.V240.Id.Id PageId
    , totalItems : Int
    }
