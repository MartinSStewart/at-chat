module Evergreen.V250.Pagination exposing (..)

import Array
import Evergreen.V250.Id
import SeqDict


type ItemId
    = ItemId Never


type PageId
    = PageId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V250.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V250.Id.Id PageId
    , previousPage : Evergreen.V250.Id.Id PageId
    , totalItems : Int
    }
