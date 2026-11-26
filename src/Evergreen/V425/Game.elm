module Evergreen.V425.Game exposing (..)

import Array
import Evergreen.V425.Go
import Evergreen.V425.Id
import Evergreen.V425.Message
import Evergreen.V425.SecretId
import Evergreen.V425.SheepGame
import Evergreen.V425.UserSession
import Evergreen.V425.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V425.Go.GameMsg
    | GoSetupMsg Evergreen.V425.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V425.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V425.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V425.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V425.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V425.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V425.Go.ValidatedSetup (Array.Array Evergreen.V425.Go.ActionWithTime) Evergreen.V425.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V425.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V425.WordSpellingGame.ActionWithTime) Evergreen.V425.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V425.SheepGame.ValidatedSetup (Array.Array Evergreen.V425.SheepGame.ActionWithTime) Evergreen.V425.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V425.SecretId.SecretId Evergreen.V425.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V425.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V425.Go.ValidatedSetup (Array.Array Evergreen.V425.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V425.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V425.WordSpellingGame.ActionWithTime) Evergreen.V425.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V425.SheepGame.ValidatedSetup (Array.Array Evergreen.V425.SheepGame.ActionWithTime) Evergreen.V425.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V425.SecretId.SecretId Evergreen.V425.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.UserSession.ToBeFilledInByBackend (Evergreen.V425.SecretId.SecretId Evergreen.V425.Id.GamePublicId))
    | LoadMatch (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V425.Go.GameModel
    | WordSpellingGame_Game Evergreen.V425.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V425.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V425.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V425.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V425.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId, Evergreen.V425.SheepGame.Input ) Int
    }
