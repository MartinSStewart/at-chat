module Evergreen.V177.Pagination exposing (..)

import Array
import Evergreen.V177.Id
import SeqDict


type ItemId
    = ItemId Never


type PageId
    = PageId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V177.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V177.Id.Id PageId
    , previousPage : Evergreen.V177.Id.Id PageId
    , totalItems : Int
    }
