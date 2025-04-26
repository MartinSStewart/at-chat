module Pagination exposing
    ( PageStatus(..)
    , Pagination
    , ToBackend(..)
    , ToFrontend(..)
    , currentPage
    , currentPageIndex
    , init
    , pageSize
    , setPage
    , totalPages
    , updateFromBackend
    , updateFromFrontend
    )

import Array exposing (Array)
import Dict exposing (Dict)
import Effect.Command as Command exposing (BackendOnly, Command, FrontendOnly)
import Effect.Lamdera as Lamdera exposing (ClientId)


{-| OpaqueVariants
-}
type PageStatus a
    = PageLoading
    | PageLoaded (Array a)


{-| OpaqueVariants
-}
type ToBackend
    = PageRequest Int


{-| OpaqueVariants
-}
type ToFrontend a
    = PageResponse { pageIndex : Int, totalPages : Int, pageData : Array a }


type alias Pagination a =
    { pages : Dict Int (PageStatus a)
    , currentPage : Int
    , totalPages : Maybe Int
    }


init : Int -> ( Pagination a, Command FrontendOnly ToBackend msg )
init pageIndex =
    setPage pageIndex { pages = Dict.empty, currentPage = 0, totalPages = Nothing }


setPage : Int -> Pagination a -> ( Pagination a, Command FrontendOnly ToBackend msg )
setPage pageIndex model =
    case Dict.get pageIndex model.pages of
        Just PageLoading ->
            ( { model | currentPage = pageIndex }, Command.none )

        Just (PageLoaded _) ->
            ( { model | currentPage = pageIndex }, Lamdera.sendToBackend (PageRequest pageIndex) )

        Nothing ->
            ( { model
                | pages = Dict.insert pageIndex PageLoading model.pages
                , currentPage = pageIndex
              }
            , Lamdera.sendToBackend (PageRequest pageIndex)
            )


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


totalPages : Pagination a -> Maybe Int
totalPages model =
    model.totalPages


updateFromFrontend : ClientId -> ToBackend -> Array a -> Command BackendOnly (ToFrontend a) msg
updateFromFrontend clientId toBackend array =
    case toBackend of
        PageRequest pageIndex ->
            PageResponse
                { pageIndex = pageIndex
                , totalPages = ((pageSize - 1) + Array.length array) // pageSize
                , pageData = Array.slice (pageIndex * pageSize) ((pageIndex + 1) * pageSize) array
                }
                |> Lamdera.sendToFrontend clientId


updateFromBackend : ToFrontend a -> Pagination a -> Pagination a
updateFromBackend toFrontend model =
    case toFrontend of
        PageResponse data ->
            { model
                | pages = Dict.insert data.pageIndex (PageLoaded data.pageData) model.pages
                , totalPages = Just data.totalPages
            }
