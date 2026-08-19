module Evergreen.V358.Pagination exposing (..)

import Array
import Evergreen.V358.Id
import SeqDict


type PageId
    = PageId Never


type ItemId
    = ItemId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V358.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V358.Id.Id PageId
    , previousPage : Evergreen.V358.Id.Id PageId
    , totalItems : Int
    }
