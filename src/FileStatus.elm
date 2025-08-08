module FileStatus exposing
    ( ContentType
    , FileHash
    , FileStatus(..)
    , FileStatusId
    , contentType
    , contentTypeToString
    , fileHash
    , fileUrl
    )

import Effect.Http as Http
import Env
import Url


type FileStatus
    = FileUploading ContentType
    | FileUploaded ContentType FileHash
    | FileError Http.Error


type FileStatusId
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
