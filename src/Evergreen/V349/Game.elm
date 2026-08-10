module Evergreen.V349.Game exposing (..)

import Array
import Evergreen.V349.Go
import Evergreen.V349.Id
import Evergreen.V349.Message
import Evergreen.V349.SecretId
import Evergreen.V349.UserSession
import Evergreen.V349.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V349.Go.GameMsg
    | GoSetupMsg Evergreen.V349.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V349.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V349.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V349.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V349.Go.ValidatedSetup (Array.Array Evergreen.V349.Go.ActionWithTime) Evergreen.V349.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V349.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V349.WordSpellingGame.ActionWithTime) Evergreen.V349.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V349.SecretId.SecretId Evergreen.V349.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.UserSession.ToBeFilledInByBackend (Evergreen.V349.SecretId.SecretId Evergreen.V349.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Evergreen.V349.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Evergreen.V349.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V349.Go.GameModel
    | WordSpellingGame_Game Evergreen.V349.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V349.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V349.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V349.Go.ValidatedSetup (Array.Array Evergreen.V349.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V349.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V349.WordSpellingGame.ActionWithTime) Evergreen.V349.WordSpellingGame.Shared
