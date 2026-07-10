module Evergreen.V311.Game exposing (..)

import Array
import Evergreen.V311.Go
import Evergreen.V311.Id
import Evergreen.V311.Message
import Evergreen.V311.SecretId
import Evergreen.V311.UserSession
import Evergreen.V311.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V311.Go.GameMsg
    | GoSetupMsg Evergreen.V311.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V311.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V311.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V311.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V311.Go.ValidatedSetup (Array.Array Evergreen.V311.Go.ActionWithTime) Evergreen.V311.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V311.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V311.WordSpellingGame.ActionWithTime) Evergreen.V311.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V311.SecretId.SecretId Evergreen.V311.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (Evergreen.V311.UserSession.ToBeFilledInByBackend (Evergreen.V311.SecretId.SecretId Evergreen.V311.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) Evergreen.V311.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) Evergreen.V311.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V311.Go.GameModel
    | WordSpellingGame_Game Evergreen.V311.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V311.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V311.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V311.Go.ValidatedSetup (Array.Array Evergreen.V311.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V311.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V311.WordSpellingGame.ActionWithTime) Evergreen.V311.WordSpellingGame.Shared
