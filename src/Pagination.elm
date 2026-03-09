module Pagination exposing
    ( PageStatus(..)
    , Pagination
    , currentPage
    , currentPageIndex
    , init
    , pageSize
    , setPage
    )

import Array exposing (Array)
import Dict exposing (Dict)


{-| OpaqueVariants
-}
type PageStatus a
    = PageLoading
    | PageLoaded (Array a)


type alias Pagination a =
    { pages : Dict Int (PageStatus a)
    , currentPage : Int
    , totalPages : Int
    }


init : Int -> Array a -> Pagination a
init pageIndex array =
    { currentPage = pageIndex
    , totalPages = ((pageSize - 1) + Array.length array) // pageSize
    , pages =
        Dict.singleton
            pageIndex
            (PageLoaded (Array.slice (pageIndex * pageSize) ((pageIndex + 1) * pageSize) array))
    }


setPage : Int -> Pagination a -> Pagination a
setPage pageIndex model =
    case Dict.get pageIndex model.pages of
        Just PageLoading ->
            { model | currentPage = pageIndex }

        Just (PageLoaded _) ->
            { model | currentPage = pageIndex }

        Nothing ->
            { model
                | pages = Dict.insert pageIndex PageLoading model.pages
                , currentPage = pageIndex
            }


currentPage : Pagination a -> Maybe (Array a)
currentPage model =
    case Dict.get model.currentPage model.pages of
        Just PageLoading ->
            Nothing

        Just (PageLoaded page) ->
            Just page

        Nothing ->
            Nothing


currentPageIndex : Pagination a -> Int
currentPageIndex model =
    model.currentPage


pageSize : number
pageSize =
    20
