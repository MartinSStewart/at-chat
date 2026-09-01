module Evergreen.V365.Pagination exposing (..)

import Array
import Evergreen.V365.Id
import SeqDict


type PageId
    = PageId Never


type ItemId
    = ItemId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V365.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V365.Id.Id PageId
    , previousPage : Evergreen.V365.Id.Id PageId
    , totalItems : Int
    }
