module Evergreen.V372.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V372.Discord
import Evergreen.V372.DiscordUserData
import Evergreen.V372.EmailAddress
import Evergreen.V372.FileStatus
import Evergreen.V372.PersonName
import Evergreen.V372.UserColor
import Evergreen.V372.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V372.PersonName.PersonName
    , color : Evergreen.V372.UserColor.UserColor
    , icon : Maybe Evergreen.V372.FileStatus.FileHash
    , email : Maybe Evergreen.V372.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V372.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) Evergreen.V372.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) DiscordFrontendCurrentUser)
