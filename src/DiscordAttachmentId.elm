module DiscordAttachmentId exposing (DiscordAttachmentId, fromUrlText)

import Url


type DiscordAttachmentId
    = DiscordAttachmentId String


fromUrlText : String -> Maybe DiscordAttachmentId
fromUrlText text =
    case Url.fromString text of
        Just url ->
            case String.split "/" url.path of
                [ "attachments", channelId, messageId, attachmentId, attachmentFileName ] ->
                    (channelId ++ "/" ++ messageId ++ "/" ++ attachmentId ++ "/" ++ attachmentFileName)
                        |> DiscordAttachmentId
                        |> Just

                _ ->
                    Nothing

        _ ->
            Nothing
