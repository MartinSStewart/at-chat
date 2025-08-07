module FileStatus exposing
    ( ContentType
    , FileHash
    , FileStatus(..)
    , contentType
    , contentTypeToString
    , fileHash
    )

import Effect.Http as Http


type FileStatus
    = FileUploading ContentType
    | FileUploaded ContentType FileHash
    | FileError Http.Error


type FileHash
    = FileHash String


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
