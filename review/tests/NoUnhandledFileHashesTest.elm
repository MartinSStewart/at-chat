module NoUnhandledFileHashesTest exposing (all)

import NoUnhandledFileHashes
import Review.Test
import Test exposing (Test, describe, test)


fileStatusModule : String
fileStatusModule =
    """module FileStatus exposing (..)

type FileHash
    = FileHash String

type alias FileData =
    { name : String, fileHash : FileHash }
"""


unlistedError : String -> String -> Review.Test.ExpectedError
unlistedError path under =
    Review.Test.error
        { message = "BackendModel holds a FileHash at " ++ path ++ " that nothing has accounted for"
        , details =
            [ "BackendExtra.orphanedFiles treats every file that nothing refers to as unused. If it doesn't know about this path, files only referred to from here would be listed as orphaned."
            , "Handle the path in BackendExtra.usedFiles and add \"" ++ path ++ "\" to `handled` in this rule's config, or add it to `excluded` if files referred to from here don't count as in use."
            ]
        , under = under
        }


staleError : String -> { message : String, details : List String }
staleError path =
    { message = "\"" ++ path ++ "\" doesn't lead to a FileHash"
    , details =
        [ "This path is listed in NoUnhandledFileHashes' config, but no path from BackendModel to a FileHash starts with it, or a shorter listed path already covers it."
        , "Remove it from the config, or correct it if a field or constructor has been renamed."
        ]
    }


all : Test
all =
    describe "NoUnhandledFileHashes"
        [ test "does not report paths that are handled or excluded" <|
            \() ->
                [ fileStatusModule
                , """module Types exposing (..)

import FileStatus exposing (FileHash)
import SeqDict exposing (SeqDict)

type alias BackendModel =
    { files : SeqDict FileHash Int
    , icon : Maybe FileHash
    , name : String
    }
"""
                ]
                    |> Review.Test.runOnModules (NoUnhandledFileHashes.rule { handled = [ "icon" ], excluded = [ "files" ] })
                    |> Review.Test.expectNoErrors
        , test "reports a path that isn't listed, at the BackendModel field it starts from" <|
            \() ->
                [ fileStatusModule
                , """module User exposing (..)

import FileStatus exposing (FileHash)

type alias BackendUser =
    { name : String, icon : Maybe FileHash }
"""
                , """module Types exposing (..)

import SeqDict exposing (SeqDict)
import User exposing (BackendUser)

type alias BackendModel =
    { users : SeqDict Int BackendUser
    }
"""
                ]
                    |> Review.Test.runOnModules (NoUnhandledFileHashes.rule { handled = [], excluded = [] })
                    |> Review.Test.expectErrorsForModules
                        [ ( "Types", [ unlistedError "users.icon" "users" ] ) ]
        , test "constructors and nested records are part of the path" <|
            \() ->
                [ fileStatusModule
                , """module Types exposing (..)

import FileStatus exposing (FileData, FileHash)

type Message
    = TextMessage { attachedFiles : List FileData }
    | EncryptedMessage (List FileHash)
    | Deleted

type alias BackendModel =
    { messages : List Message
    }
"""
                ]
                    |> Review.Test.runOnModules (NoUnhandledFileHashes.rule { handled = [ "messages.EncryptedMessage" ], excluded = [] })
                    |> Review.Test.expectErrorsForModules
                        [ ( "Types", [ unlistedError "messages.TextMessage.attachedFiles.fileHash" "messages" ] ) ]
        , test "a listed path covers every path that starts with it" <|
            \() ->
                [ fileStatusModule
                , """module Types exposing (..)

import FileStatus exposing (FileData, FileHash)

type alias Guild =
    { icon : Maybe FileHash, files : List FileData }

type alias BackendModel =
    { guilds : List Guild
    }
"""
                ]
                    |> Review.Test.runOnModules (NoUnhandledFileHashes.rule { handled = [], excluded = [ "guilds" ] })
                    |> Review.Test.expectNoErrors
        , test "reports a listed path that doesn't lead to a FileHash" <|
            \() ->
                [ fileStatusModule
                , """module Types exposing (..)

import FileStatus exposing (FileHash)

type alias BackendModel =
    { icon : Maybe FileHash
    , name : String
    }
"""
                ]
                    |> Review.Test.runOnModules (NoUnhandledFileHashes.rule { handled = [ "icon", "name", "avatar" ], excluded = [] })
                    |> Review.Test.expectGlobalErrors [ staleError "name", staleError "avatar" ]
        , test "reports a listed path that a shorter listed path already covers" <|
            \() ->
                [ fileStatusModule
                , """module Types exposing (..)

import FileStatus exposing (FileData)

type alias BackendModel =
    { files : List FileData
    }
"""
                ]
                    |> Review.Test.runOnModules (NoUnhandledFileHashes.rule { handled = [ "files.fileHash" ], excluded = [ "files" ] })
                    |> Review.Test.expectGlobalErrors [ staleError "files.fileHash" ]
        , test "doesn't follow a type argument that the type doesn't use" <|
            \() ->
                [ fileStatusModule
                , """module Encryption exposing (..)

type EncryptedData a
    = EncryptedData String
"""
                , """module Types exposing (..)

import Encryption exposing (EncryptedData)
import FileStatus exposing (FileData)

type alias BackendModel =
    { encrypted : EncryptedData FileData
    }
"""
                ]
                    |> Review.Test.runOnModules (NoUnhandledFileHashes.rule { handled = [], excluded = [] })
                    |> Review.Test.expectNoErrors
        , test "a recursive type is only walked through once per path" <|
            \() ->
                [ fileStatusModule
                , """module Types exposing (..)

import FileStatus exposing (FileHash)

type Tree
    = Leaf FileHash
    | Branch (List Tree)

type alias BackendModel =
    { tree : Tree
    }
"""
                ]
                    |> Review.Test.runOnModules (NoUnhandledFileHashes.rule { handled = [], excluded = [] })
                    |> Review.Test.expectErrorsForModules
                        [ ( "Types", [ unlistedError "tree.Leaf" "tree" ] ) ]
        ]
