module Backup exposing (main)

{-| at-chat backup downloader.

A tiny [Eco](https://eco-lang.org/) program, compiled to a native executable,
that downloads any _new_ backups from the production server's backups folder
over SSH. It performs a single incremental sync per run and then exits, so it is
meant to be triggered once a day by a systemd timer (or cron). See README.md.

The heavy lifting is done by `rsync --ignore-existing` over SSH: rsync only
transfers backup files that don't already exist locally, so re-running is cheap
and only new backups are pulled down. Everything else — reading config, checking
prerequisites, spawning rsync, reporting the result and picking an exit code —
lives here in Elm.

Configuration is read from environment variables (all optional):

  - `AT_CHAT_BACKUP_SOURCE` the remote rsync source
    (default: root@at-chat.app:/var/lib/atchat/backups/)
  - `AT_CHAT_BACKUP_DEST` the local destination directory
    (default: ./at-chat-backups)
  - `AT_CHAT_SSH_KEY` path to an SSH private key to use (default: none;
    falls back to the ssh-agent / default identities)

-}

import Eco.Console as Console
import Eco.Env as Env
import Eco.File as File
import Eco.IO.Error as IOError
import Eco.Process as Process
import Eco.Process.Error as ProcessError
import Platform
import Task exposing (Task)



-- CONFIG


type alias Config =
    { remote : String
    , dest : String
    , sshKey : Maybe String
    }


defaultRemote : String
defaultRemote =
    "root@at-chat.app:/var/lib/atchat/backups/"


defaultDest : String
defaultDest =
    "./at-chat-backups"


{-| Read configuration from the environment. Never fails; missing variables fall
back to sensible defaults.
-}
getConfig : Task Never Config
getConfig =
    Task.map3
        (\source dest key ->
            { remote = Maybe.withDefault defaultRemote source
            , dest = Maybe.withDefault defaultDest dest
            , sshKey = key
            }
        )
        (Env.lookup "AT_CHAT_BACKUP_SOURCE")
        (Env.lookup "AT_CHAT_BACKUP_DEST")
        (Env.lookup "AT_CHAT_SSH_KEY")



-- RSYNC COMMAND


{-| The `ssh` command rsync should use as its transport.

`BatchMode=yes` makes ssh fail instead of hanging on a password prompt (this runs
unattended), and `accept-new` auto-trusts the host key on first connect while
still detecting key changes afterwards.

-}
sshCommand : Config -> String
sshCommand config =
    let
        base =
            "ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=30"
    in
    case config.sshKey of
        Just keyPath ->
            base ++ " -i " ++ keyPath

        Nothing ->
            base


{-| Arguments for rsync. Each element is a separate argv entry, so there is no
shell involved and nothing needs quoting.
-}
rsyncArgs : Config -> List String
rsyncArgs config =
    [ "--archive" -- preserve timestamps/permissions
    , "--compress" -- compress during transfer
    , "--partial" -- keep partially transferred files so a re-run resumes them
    , "--ignore-existing" -- only download backups we don't already have
    , "--human-readable"
    , "--stats"
    , "-e"
    , sshCommand config
    , config.remote
    , config.dest
    ]



-- STEPS


{-| Make sure rsync is installed before we try to run it, so we can give a clear
error instead of a confusing spawn failure.
-}
ensureRsync : Task String ()
ensureRsync =
    neverToString (File.findExecutable "rsync")
        |> Task.andThen
            (\maybePath ->
                case maybePath of
                    Just _ ->
                        Task.succeed ()

                    Nothing ->
                        Task.fail "rsync was not found on PATH. Install rsync (and ssh) to use this backup downloader."
            )


{-| Create the local destination directory if it doesn't exist yet.
-}
ensureDest : Config -> Task String ()
ensureDest config =
    neverToString (File.dirExists config.dest)
        |> Task.andThen
            (\exists ->
                if exists then
                    Task.succeed ()

                else
                    File.createDir True config.dest
                        |> Task.mapError
                            (\err -> "Could not create destination " ++ config.dest ++ ": " ++ IOError.toString err)
            )


{-| Spawn rsync (inheriting stdio so its progress prints straight through) and
wait for it to finish, returning its exit code.
-}
sync : Config -> Task String Process.ExitCode
sync config =
    Process.spawn "rsync" (rsyncArgs config)
        |> Task.mapError (\err -> "Failed to start rsync: " ++ ProcessError.toString err)
        |> Task.andThen (\handle -> neverToString (Process.wait handle))



-- PROGRAM


program : Task Never ()
program =
    neverToString getConfig
        |> Task.andThen
            (\config ->
                stdoutLine ("[at-chat-backup] Syncing " ++ config.remote ++ " -> " ++ config.dest)
                    |> Task.andThen (\_ -> ensureRsync)
                    |> Task.andThen (\_ -> ensureDest config)
                    |> Task.andThen (\_ -> sync config)
                    |> Task.andThen (\code -> neverToString (report code))
            )
        |> Task.onError fail


{-| Report success/failure and exit with a matching status code so the systemd
timer records whether the run actually worked.
-}
report : Process.ExitCode -> Task Never ()
report code =
    case code of
        Process.ExitSuccess ->
            stdoutLine "[at-chat-backup] Done. Any new backups have been downloaded."
                |> Task.andThen (\_ -> Process.exit Process.ExitSuccess)

        Process.ExitFailure n ->
            stderrLine ("[at-chat-backup] rsync exited with code " ++ String.fromInt n)
                |> Task.andThen (\_ -> Process.exit (Process.ExitFailure n))


{-| Report an error from any earlier step and exit non-zero.
-}
fail : String -> Task Never ()
fail message =
    stderrLine ("[at-chat-backup] ERROR: " ++ message)
        |> Task.andThen (\_ -> Process.exit (Process.ExitFailure 1))



-- HELPERS


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



-- MAIN


main : Program () () ()
main =
    Platform.worker
        { init = \_ -> ( (), Task.attempt (\_ -> ()) program )
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = \_ -> Sub.none
        }
