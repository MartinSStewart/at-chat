module DiscordAttachmentId exposing (DiscordAttachmentId, fromUrl)


type DiscordAttachmentId
    = DiscordAttachmentId String


fromUrl : String -> DiscordAttachmentId
fromUrl text =
    String.split "?" text
        |> List.head
        |> Maybe.withDefault text
        |> String.split "attachments"
        |> List.drop 1
        |> String.join "attachments"
        |> DiscordAttachmentId
