module Evergreen.V185.Pagination exposing (..)

import Array
import Evergreen.V185.Id
import SeqDict


type ItemId
    = ItemId Never


type PageId
    = PageId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V185.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V185.Id.Id PageId
    , previousPage : Evergreen.V185.Id.Id PageId
    , totalItems : Int
    }
