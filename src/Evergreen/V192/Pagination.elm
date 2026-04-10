module Evergreen.V192.Pagination exposing (..)

import Array
import Evergreen.V192.Id
import SeqDict


type ItemId
    = ItemId Never


type PageId
    = PageId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V192.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V192.Id.Id PageId
    , previousPage : Evergreen.V192.Id.Id PageId
    , totalItems : Int
    }
