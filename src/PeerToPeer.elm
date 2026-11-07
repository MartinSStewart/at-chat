module PeerToPeer exposing
    ( Download(..)
    , Model
    , SharedFile
    , fileState
    , init
    , maxSendsAtOnce
    , maxSharedFiles
    , sendFile
    , subscriptions
    , transferUrl
    )

{-| A file over `FileStatus.maxUploadSize` isn't uploaded. It stays on the device it was
attached from, and when someone presses it, the server asks that device to send it and passes
the bytes straight on to them (see rust-server/src/peer\_to\_peer.rs).

The device only has the file while the tab it was attached in stays open, since a browser
won't hand a page a file again without the person picking it. Each connection tells the
backend which files it is sharing, and the backend forgets them when the connection closes.

-}

import Effect.Command exposing (Command, FrontendOnly)
import Effect.File exposing (File)
import Effect.Http as Http
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Time as Time
import FileName exposing (FileName)
import FileStatus exposing (PeerToPeerFileState(..), PeerToPeerId)
import Id exposing (GuildOrDmId, Id, UserId)
import SHA256
import SecretId exposing (SecretId, ServerSecret)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Url


{-| The files this tab is sharing, and how the ones the user asked for from other people are
getting on.
-}
type alias Model =
    { shared : SeqDict PeerToPeerId { file : File, sharedFile : SharedFile }
    , downloads : SeqDict ( Id UserId, PeerToPeerId ) Download
    , pickedDifferentFile : SeqSet PeerToPeerId
    , sending : SeqDict PeerToPeerId (SeqDict String Float)
    }


type Download
    = Requested
    | UploaderOffline


{-| What the backend keeps about each file a connection is sharing. The size and name come from
the uploader, since only the uploader can say what the file really is: an encrypted message
hides its attachments from the backend.
-}
type alias SharedFile =
    { guildOrDmId : GuildOrDmId
    , fileName : FileName
    , fileSize : Int
    }


init : Model
init =
    { shared = SeqDict.empty, downloads = SeqDict.empty, pickedDifferentFile = SeqSet.empty, sending = SeqDict.empty }


{-| More than anyone would share at once, while still stopping a connection from filling the
backend's memory.
-}
maxSharedFiles : Int
maxSharedFiles =
    1000


{-| Each download someone asks for is a whole upload from this device, so this keeps anyone
from using up the uploader's connection by asking for the same file many times at once.
-}
maxSendsAtOnce : Int
maxSendsAtOnce =
    2


fileState : Id UserId -> Id UserId -> PeerToPeerId -> Model -> PeerToPeerFileState
fileState currentUserId uploader peerToPeerId model =
    if currentUserId == uploader then
        if SeqDict.member peerToPeerId model.shared then
            case SeqDict.get peerToPeerId model.sending |> Maybe.map SeqDict.values of
                Just (first :: rest) ->
                    PeerToPeerSendingFromHere first rest

                Just [] ->
                    PeerToPeerSharedFromHere

                Nothing ->
                    PeerToPeerSharedFromHere

        else if SeqSet.member peerToPeerId model.pickedDifferentFile then
            PeerToPeerPickedDifferentFile

        else
            PeerToPeerNotSharedFromHere

    else
        case SeqDict.get ( uploader, peerToPeerId ) model.downloads of
            Just Requested ->
                PeerToPeerRequested

            Just UploaderOffline ->
                PeerToPeerUploaderOffline

            Nothing ->
                PeerToPeerAvailable


{-| Both the uploader and the downloader are given this. The signature is checked by the Rust
server, which knows the server secret too, so that it only passes on files that were attached
to messages and only for as long as the link is new.
-}
transferUrl : Time.Posix -> SecretId ServerSecret -> SecretId transfer -> SharedFile -> String
transferUrl time serverSecret transferId sharedFile =
    let
        expires : String
        expires =
            Time.posixToMillis time + 120000 |> String.fromInt

        size : String
        size =
            String.fromInt sharedFile.fileSize

        transferId2 : String
        transferId2 =
            SecretId.toString transferId

        name : String
        name =
            FileName.toString sharedFile.fileName
    in
    FileStatus.domain
        ++ "/file/p2p/"
        ++ transferId2
        ++ "?size="
        ++ size
        ++ "&expires="
        ++ expires
        ++ "&token="
        ++ transferToken serverSecret transferId2 size expires name
        ++ "&name="
        ++ Url.percentEncode name


{-| Has to match `transfer_token` in rust-server/src/peer\_to\_peer.rs. The name is signed too so
that someone holding a link can't change what the download gets saved as.
-}
transferToken : SecretId ServerSecret -> String -> String -> String -> String -> String
transferToken serverSecret transferId size expires name =
    -- Sha256.sha256 doesn't hash a name outside ASCII the way Rust does, while this one hashes its UTF-8.
    SHA256.fromString (SecretId.toString serverSecret ++ ":p2p:" ++ transferId ++ ":" ++ size ++ ":" ++ expires ++ ":" ++ name)
        |> SHA256.toHex


{-| The whole file goes in one request. A browser streams a file body from disk rather than
reading it into memory first, so its size doesn't matter here.
-}
sendFile : (Result Http.Error () -> msg) -> String -> File -> Command restriction toFrontend msg
sendFile onResult url file =
    Http.request
        { method = "POST"
        , headers = []
        , url = url
        , body = Http.fileBody file
        , expect = Http.expectWhatever onResult
        , timeout = Nothing

        -- Each send has its own url, so it doubles as the name to track it by.
        , tracker = Just url
        }


subscriptions : (PeerToPeerId -> String -> Http.Progress -> msg) -> Model -> Subscription FrontendOnly msg
subscriptions onProgress model =
    SeqDict.foldl
        (\peerToPeerId sends list ->
            SeqDict.foldl (\url _ list2 -> Http.track url (onProgress peerToPeerId url) :: list2) list sends
        )
        []
        model.sending
        |> Subscription.batch
