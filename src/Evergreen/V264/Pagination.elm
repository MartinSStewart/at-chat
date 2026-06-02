module Evergreen.V264.Pagination exposing (..)

import Array
import Evergreen.V264.Id
import SeqDict


type ItemId
    = ItemId Never


type PageId
    = PageId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V264.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V264.Id.Id PageId
    , previousPage : Evergreen.V264.Id.Id PageId
    , totalItems : Int
    }
