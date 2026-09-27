module Evergreen.V386.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V386.Discord
import Evergreen.V386.DiscordUserData
import Evergreen.V386.EmailAddress
import Evergreen.V386.FileStatus
import Evergreen.V386.PersonName
import Evergreen.V386.UserColor
import Evergreen.V386.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V386.PersonName.PersonName
    , color : Evergreen.V386.UserColor.UserColor
    , icon : Maybe Evergreen.V386.FileStatus.FileHash
    , email : Maybe Evergreen.V386.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V386.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) Evergreen.V386.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) DiscordFrontendCurrentUser)
