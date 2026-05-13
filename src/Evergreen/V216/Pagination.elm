module Evergreen.V216.Pagination exposing (..)

import Array
import Evergreen.V216.Id
import SeqDict


type ItemId
    = ItemId Never


type PageId
    = PageId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V216.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V216.Id.Id PageId
    , previousPage : Evergreen.V216.Id.Id PageId
    , totalItems : Int
    }
