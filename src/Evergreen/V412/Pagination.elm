module Evergreen.V412.Pagination exposing (..)

import Array
import Evergreen.V412.Id
import SeqDict


type PageId
    = PageId Never


type ItemId
    = ItemId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V412.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V412.Id.Id PageId
    , previousPage : Evergreen.V412.Id.Id PageId
    , totalItems : Int
    }
