module Pagination exposing
    ( ItemId(..)
    , PageId(..)
    , PageStatus(..)
    , Pagination
    , addItem
    , currentPage
    , init
    , itemToPageId
    , offsetToItemId
    , pageCount
    , pageSize
    , setPage
    , updateItem
    , viewPage
    )

import Array exposing (Array)
import Array.Extra
import Dict exposing (Dict)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Icons
import Id exposing (Id)
import SeqDict exposing (SeqDict)
import Ui exposing (Element)
import UserSession exposing (ToBeFilledInByBackend(..))


{-| OpaqueVariants
-}
type PageStatus a
    = PageLoading
    | PageLoaded (Array a)


{-| OpaqueVariants
-}
type PageId
    = PageId Never


{-| OpaqueVariants
-}
type ItemId
    = ItemId Never


itemToPageId : Id ItemId -> { pageId : Id PageId, offset : Int }
itemToPageId itemId =
    let
        itemId2 : Int
        itemId2 =
            Id.toInt itemId
    in
    { pageId = itemId2 // pageSize |> Id.fromInt, offset = modBy pageSize itemId2 }


type alias Pagination a =
    { pages : SeqDict (Id PageId) (PageStatus a)
    , currentPage : Id PageId
    , previousPage : Id PageId
    , totalItems : Int
    }


init : Id PageId -> Array a -> Pagination a
init pageId array =
    { currentPage = pageId
    , totalItems = Array.length array --
    , previousPage = pageId
    , pages =
        SeqDict.singleton
            pageId
            (PageLoaded (Array.slice (Id.toInt pageId * pageSize) ((Id.toInt pageId + 1) * pageSize) array))
    }


addItem : a -> Pagination a -> Pagination a
addItem item model =
    { model
        | totalItems = model.totalItems + 1
        , pages =
            SeqDict.updateIfExists
                ((pageSize + model.totalItems) // pageSize |> Id.fromInt)
                (\page ->
                    case page of
                        PageLoaded array ->
                            Array.push item array |> PageLoaded

                        PageLoading ->
                            page
                )
                model.pages
    }


pageCount : Pagination a -> Int
pageCount model =
    ((pageSize - 1) + model.totalItems) // pageSize


updateItem : Id ItemId -> (a -> a) -> Pagination a -> Pagination a
updateItem itemIndex updateFunc model =
    let
        { pageId, offset } =
            itemToPageId itemIndex
    in
    { model
        | pages =
            SeqDict.updateIfExists
                pageId
                (\page ->
                    case page of
                        PageLoaded page2 ->
                            Array.Extra.update offset updateFunc page2 |> PageLoaded

                        PageLoading ->
                            page
                )
                model.pages
    }


setPage : Id PageId -> ToBeFilledInByBackend (Array a) -> Pagination a -> Pagination a
setPage pageId filledInByBackend model =
    case filledInByBackend of
        FilledInByBackend data ->
            { model
                | pages = SeqDict.insert pageId (PageLoaded data) model.pages
                , currentPage = pageId
                , previousPage = model.currentPage
            }

        EmptyPlaceholder ->
            case SeqDict.get pageId model.pages of
                Just PageLoading ->
                    { model | currentPage = pageId, previousPage = model.currentPage }

                Just (PageLoaded _) ->
                    { model | currentPage = pageId, previousPage = model.currentPage }

                Nothing ->
                    { model
                        | pages = SeqDict.insert pageId PageLoading model.pages
                        , currentPage = pageId
                        , previousPage = model.currentPage
                    }


currentPage : Id PageId -> Pagination a -> Maybe (Array a)
currentPage pageId model =
    case SeqDict.get pageId model.pages of
        Just PageLoading ->
            Nothing

        Just (PageLoaded page) ->
            Just page

        Nothing ->
            Nothing


viewPage : HtmlId -> (Id ItemId -> a -> Element msg) -> Pagination a -> Element msg
viewPage htmlId itemView model =
    case SeqDict.get model.currentPage model.pages of
        Just (PageLoaded page) ->
            List.indexedMap
                (\index log -> itemView (offsetToItemId index model) log)
                (Array.toList page)
                |> Ui.column [ Ui.id (Dom.idToString htmlId) ]
                |> Ui.el []

        _ ->
            case SeqDict.get model.previousPage model.pages of
                Just (PageLoaded page) ->
                    List.indexedMap
                        (\index log -> itemView (offsetToItemId index model) log)
                        (Array.toList page)
                        |> Ui.column
                            [ Ui.id (Dom.idToString htmlId)
                            , Ui.opacity 0
                            ]
                        |> Ui.el [ Ui.inFront (Ui.row [ Ui.spacing 8 ] [ Ui.text "Loading", Icons.spinner ]) ]

                _ ->
                    Ui.row [ Ui.spacing 8 ] [ Ui.text "Loading", Icons.spinner ]


offsetToItemId : Int -> Pagination a -> Id ItemId
offsetToItemId index model =
    pageSize * Id.toInt model.currentPage + index |> Id.fromInt


pageSize : number
pageSize =
    20
