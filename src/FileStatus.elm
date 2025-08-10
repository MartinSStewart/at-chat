module FileStatus exposing
    ( ContentType
    , FileData
    , FileHash
    , FileId
    , FileStatus(..)
    , addFileHash
    , contentType
    , fileHash
    , fileUploadPreview
    , fileUrl
    , isImage
    , isText
    , onlyUploadedFiles
    , sizeToString
    , upload
    )

import Effect.Command exposing (Command)
import Effect.File exposing (File)
import Effect.Http as Http
import Effect.Lamdera as Lamdera exposing (SessionId)
import Env
import FileName exposing (FileName)
import Icons
import Id exposing (Id)
import MyUi
import NonemptyDict exposing (NonemptyDict)
import Round
import SeqDict exposing (SeqDict)
import StringExtra
import Ui
import Ui.Font
import Ui.Input
import Ui.Shadow
import Url


type alias FileData =
    { fileName : FileName, fileSize : Int, contentType : ContentType, fileHash : FileHash }


type FileStatus
    = FileUploading FileName Int ContentType
    | FileUploaded FileData
    | FileError Http.Error


type FileId
    = FileStatusId Never


type FileHash
    = FileHash String


sizeToString : Int -> String
sizeToString int =
    if int < 1024 then
        String.fromInt int ++ " bytes"

    else if int < 1024 * 1024 then
        StringExtra.removeTrailing0s 1 (toFloat int / 1024) ++ "kb"

    else
        StringExtra.removeTrailing0s 1 (toFloat int / (1024 * 1024)) ++ "mb"


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


upload : (Result Http.Error String -> msg) -> SessionId -> File -> Command restriction toFrontend msg
upload onResult sessionId file2 =
    Http.request
        { method = "POST"
        , headers = [ Http.header "sid" (Lamdera.sessionIdToString sessionId) ]
        , url =
            if Env.isProduction then
                Env.domain ++ "/file/upload"

            else
                "http://localhost:3000/file/upload"
        , body = Http.fileBody file2
        , expect = Http.expectString onResult
        , timeout = Nothing
        , tracker = Nothing
        }


fileUploadPreview : (Id FileId -> msg) -> NonemptyDict (Id FileId) FileStatus -> Ui.Element msg
fileUploadPreview onPressDelete filesToUpload2 =
    Ui.row
        [ Ui.spacing 2
        , Ui.move { x = 0, y = -100, z = 0 }
        , Ui.width Ui.shrink
        , Ui.paddingXY 8 0
        ]
        (List.map
            (\( fileStatusId, fileStatus ) ->
                Ui.el
                    [ Ui.width (Ui.px 100)
                    , Ui.height (Ui.px 100)
                    , Ui.Shadow.shadows
                        [ { x = 0
                          , y = -2
                          , size = 0
                          , blur = 8
                          , color = Ui.rgba 0 0 0 0.5
                          }
                        ]
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
                    , Ui.el
                        [ Ui.alignBottom
                        , Ui.padding 4
                        , Ui.Font.bold
                        , Ui.Shadow.font
                            { offset = ( 0, 0 )
                            , blur = 2
                            , color = Ui.rgb 0 0 0
                            }
                        ]
                        (Ui.text ("[!" ++ Id.toString fileStatusId ++ "]"))
                        |> Ui.inFront
                    ]
                    (case fileStatus of
                        FileUploading _ _ _ ->
                            Ui.none

                        FileUploaded fileData ->
                            if isImage fileData.contentType then
                                Ui.image
                                    [ Ui.width (Ui.px 98)
                                    , Ui.height (Ui.px 98)
                                    , Ui.rounded 8
                                    , Ui.clip
                                    , Ui.centerX
                                    , Ui.centerY
                                    ]
                                    { source = fileUrl fileData.contentType fileData.fileHash
                                    , description = ""
                                    , onLoad = Nothing
                                    }

                            else if isText fileData.contentType then
                                Ui.el
                                    [ Ui.width (Ui.px 42)
                                    , Ui.centerX
                                    , Ui.centerY
                                    , Ui.Font.color MyUi.font3
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
                                    , Ui.Font.color MyUi.font3
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


addFileHash : Result Http.Error String -> FileStatus -> FileStatus
addFileHash result fileStatus =
    case fileStatus of
        FileUploading fileName fileSize contentType2 ->
            case result of
                Ok fileHash2 ->
                    FileUploaded
                        { fileName = fileName
                        , fileSize = fileSize
                        , contentType = contentType2
                        , fileHash = fileHash fileHash2
                        }

                Err error ->
                    FileError error

        FileUploaded _ ->
            fileStatus

        FileError error ->
            fileStatus


onlyUploadedFiles : SeqDict (Id FileId) FileStatus -> SeqDict (Id FileId) FileData
onlyUploadedFiles dict =
    SeqDict.filterMap
        (\_ status ->
            case status of
                FileUploading _ _ _ ->
                    Nothing

                FileUploaded fileData ->
                    Just fileData

                FileError _ ->
                    Nothing
        )
        dict
