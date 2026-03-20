module Evergreen.V160.Pagination exposing (..)

import Array
import Evergreen.V160.Id
import SeqDict


type ItemId
    = ItemId Never


type PageId
    = PageId Never


type PageStatus a
    = PageLoading
    | PageLoaded (Array.Array a)


type alias Pagination a =
    { pages : SeqDict.SeqDict (Evergreen.V160.Id.Id PageId) (PageStatus a)
    , currentPage : Evergreen.V160.Id.Id PageId
    , previousPage : Evergreen.V160.Id.Id PageId
    , totalItems : Int
    }
