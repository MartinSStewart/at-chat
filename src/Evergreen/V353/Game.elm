module Evergreen.V353.Game exposing (..)

import Array
import Evergreen.V353.Go
import Evergreen.V353.Id
import Evergreen.V353.Message
import Evergreen.V353.SecretId
import Evergreen.V353.UserSession
import Evergreen.V353.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V353.Go.GameMsg
    | GoSetupMsg Evergreen.V353.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V353.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V353.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V353.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V353.Go.ValidatedSetup (Array.Array Evergreen.V353.Go.ActionWithTime) Evergreen.V353.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V353.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V353.WordSpellingGame.ActionWithTime) Evergreen.V353.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V353.SecretId.SecretId Evergreen.V353.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.UserSession.ToBeFilledInByBackend (Evergreen.V353.SecretId.SecretId Evergreen.V353.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Evergreen.V353.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Evergreen.V353.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V353.Go.GameModel
    | WordSpellingGame_Game Evergreen.V353.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V353.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V353.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V353.Go.ValidatedSetup (Array.Array Evergreen.V353.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V353.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V353.WordSpellingGame.ActionWithTime) Evergreen.V353.WordSpellingGame.Shared
