module Evergreen.V312.Pagination exposing (..)

import Array
import Evergreen.V312.Id
import SeqDict


type PageId
    = PageId Never


type ItemId
    = ItemId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V312.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V312.Id.Id PageId
    , previousPage : Evergreen.V312.Id.Id PageId
    , totalItems : Int
    }
