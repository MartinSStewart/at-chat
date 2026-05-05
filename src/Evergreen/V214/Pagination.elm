module Evergreen.V214.Pagination exposing (..)

import Array
import Evergreen.V214.Id
import SeqDict


type ItemId
    = ItemId Never


type PageId
    = PageId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V214.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V214.Id.Id PageId
    , previousPage : Evergreen.V214.Id.Id PageId
    , totalItems : Int
    }
