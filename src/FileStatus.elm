module FileStatus exposing
    ( ContentType
    , FileHash
    , FileId
    , FileStatus(..)
    , contentType
    , contentTypeToString
    , fileHash
    , fileUploadPreview
    , fileUrl
    , isImage
    , isText
    )

import Effect.Http as Http
import Env
import Icons
import Id exposing (Id)
import MyUi
import NonemptyDict
import Ui
import Ui.Font
import Ui.Input
import Url


type FileStatus
    = FileUploading ContentType
    | FileUploaded ContentType FileHash
    | FileError Http.Error


type FileId
    = FileStatusId Never


type FileHash
    = FileHash String


fileUrl : ContentType -> FileHash -> String
fileUrl (ContentType contentType2) (FileHash fileHash2) =
    (if Env.isProduction then
        "/"

     else
        "http://localhost:3000/"
    )
        ++ "file/"
        ++ Url.percentEncode contentType2
        ++ "/"
        ++ fileHash2


isImage : ContentType -> Bool
isImage (ContentType contentType2) =
    String.startsWith "image/" contentType2


isText : ContentType -> Bool
isText (ContentType contentType2) =
    String.startsWith "text/" contentType2


fileHash : String -> FileHash
fileHash =
    FileHash


type ContentType
    = ContentType String


contentType : String -> ContentType
contentType =
    ContentType


contentTypeToString : ContentType -> String
contentTypeToString (ContentType a) =
    a


fileUploadPreview : (Id FileId -> msg) -> NonemptyDict.NonemptyDict (Id FileId) FileStatus -> Ui.Element msg
fileUploadPreview onPressDelete filesToUpload2 =
    Ui.row
        [ Ui.spacing 2, Ui.move { x = 0, y = -100, z = 0 }, Ui.width Ui.shrink ]
        (List.map
            (\( fileStatusId, fileStatus ) ->
                Ui.el
                    [ Ui.width (Ui.px 100)
                    , Ui.height (Ui.px 100)
                    , Ui.background MyUi.background1
                    , Ui.borderColor MyUi.background1
                    , Ui.border 1
                    , Ui.rounded 8
                    , Ui.el
                        [ Ui.width (Ui.px 42)
                        , Ui.height (Ui.px 42)
                        , Ui.Input.button (onPressDelete fileStatusId)
                        , Ui.rounded 16
                        , Ui.move { x = -3, y = -3, z = 0 }
                        ]
                        (Ui.el
                            [ Ui.width (Ui.px 28)
                            , Ui.height (Ui.px 28)
                            , Ui.rounded 16
                            , Ui.contentCenterX
                            , Ui.contentCenterY
                            , Ui.background MyUi.deleteButtonBackground
                            ]
                            (Ui.html (Icons.delete 19))
                        )
                        |> Ui.inFront
                    ]
                    (case fileStatus of
                        FileUploading _ ->
                            Ui.none

                        FileUploaded contentType2 fileHash2 ->
                            if isImage contentType2 then
                                Ui.image
                                    [ Ui.width (Ui.px 98)
                                    , Ui.height (Ui.px 98)
                                    , Ui.rounded 8
                                    , Ui.clip
                                    , Ui.centerX
                                    , Ui.centerY
                                    ]
                                    { source = fileUrl contentType2 fileHash2
                                    , description = ""
                                    , onLoad = Nothing
                                    }

                            else if isText contentType2 then
                                Ui.el
                                    [ Ui.width (Ui.px 42)
                                    , Ui.centerX
                                    , Ui.centerY
                                    ]
                                    (Ui.html Icons.document)

                            else
                                Ui.el
                                    [ Ui.Font.bold
                                    , Ui.Font.letterSpacing -1
                                    , Ui.Font.lineHeight 1.1
                                    , Ui.centerX
                                    , Ui.centerY
                                    , MyUi.prewrap
                                    ]
                                    (Ui.text "0110\n0001")

                        FileError error ->
                            Ui.el
                                [ Ui.centerX
                                , Ui.centerY
                                , Ui.width Ui.shrink
                                ]
                                (Ui.html Icons.x)
                    )
            )
            (NonemptyDict.toList filesToUpload2)
        )
