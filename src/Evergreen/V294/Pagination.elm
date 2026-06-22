module Evergreen.V294.Pagination exposing (..)

import Array
import Evergreen.V294.Id
import SeqDict


type ItemId
    = ItemId Never


type PageId
    = PageId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V294.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V294.Id.Id PageId
    , previousPage : Evergreen.V294.Id.Id PageId
    , totalItems : Int
    }
