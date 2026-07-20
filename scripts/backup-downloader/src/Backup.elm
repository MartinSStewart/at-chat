module Backup exposing (main)

import Eco.Console as Console
import Eco.File as File
import Eco.IO.Error as IOError
import Eco.Process as Process
import Eco.Process.Error as ProcessError
import Platform
import Task exposing (Task)


main : Program () () ()
main =
    Platform.worker
        { init = \_ -> ( (), Task.attempt (\_ -> ()) program )
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


defaultRemote : String
defaultRemote =
    "root@at-chat.app:/var/lib/atchat/backups/"


defaultDest : String
defaultDest =
    "./at-chat-backups"


{-| Arguments for rsync. Each element is a separate argv entry, so there is no
shell involved and nothing needs quoting.
-}
rsyncArgs : List String
rsyncArgs =
    [ "--archive" -- preserve timestamps/permissions
    , "--compress" -- compress during transfer
    , "--partial" -- keep partially transferred files so a re-run resumes them
    , "--ignore-existing" -- only download backups we don't already have
    , "--human-readable"
    , "--stats"
    , "-e"
    , "ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=30"
    , defaultRemote
    , defaultDest
    ]


program : Task String ()
program =
    stdoutLine ("[at-chat-backup] Syncing " ++ defaultRemote ++ " -> " ++ defaultDest)
        |> Task.andThen
            (\() ->
                neverToString (File.findExecutable "rsync")
                    |> Task.andThen
                        (\maybePath ->
                            case maybePath of
                                Just _ ->
                                    Task.succeed ()

                                Nothing ->
                                    Task.fail "rsync was not found on PATH. Install rsync (and ssh) to use this backup downloader."
                        )
            )
        |> Task.andThen
            (\() ->
                neverToString (File.dirExists defaultDest)
                    |> Task.andThen
                        (\exists ->
                            if exists then
                                Task.succeed ()

                            else
                                File.createDir True defaultDest
                                    |> Task.mapError
                                        (\err -> "Could not create destination " ++ defaultDest ++ ": " ++ IOError.toString err)
                        )
            )
        |> Task.andThen
            (\() ->
                Process.spawn "rsync" rsyncArgs
                    |> Task.mapError (\err -> "Failed to start rsync: " ++ ProcessError.toString err)
                    |> Task.andThen (\handle -> neverToString (Process.wait handle))
            )
        |> Task.andThen
            (\code ->
                case code of
                    Process.ExitSuccess ->
                        stdoutLine "[at-chat-backup] Done. Any new backups have been downloaded."
                            |> Task.andThen (\() -> Process.exit Process.ExitSuccess |> neverToString)

                    Process.ExitFailure n ->
                        stderrLine ("[at-chat-backup] rsync exited with code " ++ String.fromInt n)
                            |> Task.andThen (\_ -> Process.exit (Process.ExitFailure n))
                            |> neverToString
            )


stdoutLine : String -> Task String ()
stdoutLine text =
    neverToString (ignoreError (Console.write Console.stdout (text ++ "\n")))


stderrLine : String -> Task Never ()
stderrLine text =
    ignoreError (Console.write Console.stderr (text ++ "\n"))


{-| Discard the value and any error of a task, turning it into a task that always
succeeds. Used for logging, where a failed write should never abort the program.
-}
ignoreError : Task x a -> Task Never ()
ignoreError task =
    task
        |> Task.map (\_ -> ())
        |> Task.onError (\_ -> Task.succeed ())


{-| Widen a task that can never fail into any error type, so it can be chained
with `andThen` inside a `Task String _` pipeline.
-}
neverToString : Task Never a -> Task String a
neverToString =
    Task.mapError never
